# Phase 7: Pilot — 12 Albums End to End - Pattern Map

**Mapped:** 2026-09-25
**Files analyzed:** 16 (11 repo files created/modified + 5 plan-artifact shapes)
**Analogs found:** 15 / 16 (one partial: D-12's self-test has no in-file precedent — `diff-music-tags.sh` has **no `--self-test` today**)

> Line numbers below were read on 2026-09-25 at HEAD `bce8984`. Per CONVENTIONS.md's preamble and
> the `gsd-plan-line-citations-go-stale` memory note, **cite by symbol/heading in plans**; the line
> numbers here are for the planner's navigation only and will drift.

---

## ⚠ Couplings the CONTEXT file list does not name (read before assigning plans)

These were found while extracting analogs. Each one breaks the moment D-22 lands, and none is in
07-CONTEXT.md's list of edited files. They are measured, not inferred:

| # | Coupling | Where | Effect when `/media` goes `:rw` |
|---|----------|-------|--------------------------------|
| C1 | **`import.move` is ALREADY `no` / `copy: yes` in the vendored config** | `stacks/selfhosted/arrs/beets/config.yaml` lines 311-312 (`copy: yes` / `move: no`, under `import:`) | D-22 item 2 ("`import.move` → `copy`") is a **no-op in the repo**. The `import.move: yes` in `CLAUDE.md` § Constraints is stale or describes the *host* copy. The plan must **measure** the appdata copy on LXC 100 (`/mnt/fast/appdata/arrs/beets/config/config.yaml`) and the in-container effective config before deciding what D-22 changes — and must not write a "changed move→copy" claim for a key that was already `copy`. |
| C2 | **The `01-auto` registration lives in `flask-config.yaml`, not `flask.yaml`** | `flask-config.yaml` lines 80-83 (`"01-auto": name/path/autotag: auto`) | D-21's edit target is `flask-config.yaml`. |
| C3 | **`gui.library.readonly: true` in `flask-config.yaml`** | `flask-config.yaml` lines 123-129 (`library:` → `readonly: true`, "a beets-flask UI GUARD, NOT A MOUNT") | A beets-flask-driven import (D-20, `02-review`) will likely be refused by the UI guard even after the mount is `:rw`. D-22's "one commit carries every behaviour flag that moves with it" should include this key, or explicitly argue why not. |
| C4 | **flask readiness gate says "fewer than three [inboxes] is a RED"** | `flask.yaml` lines 213-227 (READINESS GATE comment); `flask-config.yaml` lines 65-72 | De-registering `01-auto` makes the correct count **two**. Any gate/acceptance text asserting three must move in the same commit. |
| C5 | **`quick-health-check.sh` D-03 block asserts D-05 (`/media` RW=false) on BOTH containers** | `quick-health-check.sh` lines 1706-1708 (comment), 1774-1783 (flask runtime arm), 1834-1841 (CLI render arm) | Goes ❌ `D-05 VIOLATED` the moment D-22 deploys. D-23's standing assertion **replaces/inverts these arms** — it is not an additional block. |
| C6 | **`check-music-freeze.sh` mount census fails any tagger-capable container holding rw on Music** | `check-music-freeze.sh` lines 1032-1058 (`RW_TAGGER` → `fail "rw on Music: … (tagger-capable)"`); section-1 `TAGGER_WRITERS` lines 372-386; summary line 1121 | beets-flask holding `/mnt/tank/media:rw` is exactly this red. It is folded into `quick-health-check.sh`, so the routine check goes red. Needs a named Phase-7 exception shaped like the existing `CONSUMER_PATTERN` / "D-21 consumer exception" arm (lines 1040-1046), counted on its own line — not a silent skip. |
| C7 | **`phase06-oracle.sh --run` step 2 asserts `/media` RW=false** | `phase06-oracle.sh` lines 769-793 (`assert_media_readonly`), 2838-2849 (step 2 call site, `bad "layer 1: $RW_WHY"`) | D-30's "first real `--run`" will take a **red** on layer 1 if it runs after D-22. Sequence the `--run` **before** the grant, or re-scope layer 1 with an explicit, driven change. |
| C8 | **`phase06-oracle.sh --run` asserts `library.db` sha == `FIXTURE_LIB_SHA256`** | `phase06-oracle.sh` line 246 (`FIXTURE_LIB_SHA256="fbbdde0c…"`), lines 2905-2912 | After the first pilot import the real `library.db` changes, so every later `--run` goes `bad` on this line. Same sequencing consequence as C7. |
| C9 | **Vendored-drift block compares repo ↔ appdata for `config.yaml` AND `flask-config.yaml`** | `quick-health-check.sh` lines 1611-1624 (`_drift_pair survivor-config.yaml …`, `_drift_pair flask-config.yaml …`) | Editing either file in the repo without installing it to `/mnt/fast/appdata/arrs/beets/config/…` in the same step turns the drift block red. |
| C10 | **The vendored config digest has already moved once since the 06-04 proof** | 06-04 recorded `config.yaml 96a7c622…` (`artifacts/06-04-first-start.txt` lines 160, 248); HEAD's file hashes `661c7297…` (last touched `1a64286`, 2026-09-21) | D-22's "PREVIOUS digest and the commit that produced it" must be **measured** (`git show <base>:stacks/selfhosted/arrs/beets/config.yaml \| shasum -a 256` plus the appdata copy on LXC 100), not copied from the 06-04 artifact. `flask-config.yaml` still hashes `949bd1f3…`, matching 06-04. |
| C11 | **`fast` and `tank` are different pools** | D-16 fences `tank/media/Music` + `fast/appdata/arrs` | `zfs snapshot a@x b@y` is only atomic within one pool. "One remote step" is achievable; "one atomic snapshot" is not. The fence step must list **both** back and assert both before any write (06-41 pattern), and say which was taken first. |

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/diff-music-tags.sh` (modify: D-11 AMBIGUOUS, exit 3) | utility / gate | transform (NDJSON join) | itself (`JOIN_JQ`, exit block) + `check-music-consumers.sh` exit ladder | exact (self) |
| `scripts/diff-music-tags.sh` (add: D-12 `--self-test`, 2 fixtures) | test harness | batch (synthetic fixtures) | `scripts/check-beets-config.sh` `run_self_test()` | role-match |
| `scripts/check-music-import.sh` (NEW, D-25) | health check | batch read over ssh (atlantis / container) | `scripts/check-music-consumers.sh` (script shape, exit ladder, 📊 Summary) + `quick-health-check.sh` underscore-dir guard (atlantis scan) + `phase06-oracle.sh` `assert_no_collision_suffix` (class-1 predicate) | exact (composite) |
| `scripts/quick-health-check.sh` (modify: D-25 fold-in block) | health check aggregator | request-response over ssh | the consumers fold-in (lines 2516-2715) | exact |
| `scripts/quick-health-check.sh` (modify: D-23 `rw`-by-decision assertion) | health check | request-response (docker inspect) | D-03 block (lines 1717-1783) | exact (inversion of existing arm) |
| `scripts/quick-health-check.sh` (modify: D-27 exemption register) | health check | static scan | D-04 block (`D04_EXEMPT_RE`, `D04_EXEMPT_BASELINE`) | exact |
| `scripts/check-music-freeze.sh` (modify, implied by C6) | health check | request-response (docker inspect) | its own `CONSUMER_PATTERN` / "D-21 consumer exception" arm | exact |
| `scripts/check-music-consumers.sh` (modify: D-24 30-item, D-28 aunique) | health check | request-response (REST) | its own section 4b loop over `ARTIST_PROOF_ROWS` + `jf_api` / `ma_api` | exact |
| `stacks/selfhosted/arrs/beets/config.yaml` (modify: D-22) | config | — | its own `import:` stanza (lines 302-339) | exact |
| `stacks/selfhosted/arrs/beets/beets.yaml` (modify: `:ro`→`:rw`) | config (compose) | — | its own retraction-in-place comment style (lines 94-116) | exact |
| `stacks/selfhosted/arrs/beets/flask.yaml` (modify: `:ro`→`:rw`) | config (compose) | — | its own D-05 block (lines 147-161) | exact |
| `stacks/selfhosted/arrs/beets/flask-config.yaml` (modify: D-21, C3) | config | — | its own `folders:` block (lines 76-104) | exact |
| `stacks/selfhosted/arrs/beets.md` (modify: closure + head pointer) | doc | — | its own head blockquote (lines 16-38) | exact |
| `scripts/phase06-oracle.sh` (exercise; possibly modify per C7/C8) | test oracle | request-response | itself | exact |
| `scripts/snapshot-music-tags.sh` (exercise only — AFTER capture) | utility | file-I/O batch | itself | exact |
| Plan-artifact shapes: fence step (D-16), snapshot register + prune gate (D-19), evidence map (D-31), frozen oracle rows (D-07) | plan / artifact | — | 06-41-PLAN.md Task 2; 06-52-PLAN.md Tasks 1-2; CONVENTIONS.md §10 | exact |

---

## Pattern Assignments

### `scripts/diff-music-tags.sh` — D-11 AMBIGUOUS classification (utility, transform)

**Analog:** itself. 300 lines, `set -euo pipefail` at line 53.

**The defect, verbatim** (lines 155-165):
```bash
JOIN_JQ='
  def index: reduce .[] as $r ({}; .[$r.k] = $r);
  def dupgroups: group_by(.k) | map(select(length > 1))
                 | map({ audio_md5: .[0].k, paths: (map(.p) | unique) })
                 | map(select(.paths | length > 1));

  ($B | index) as $bi | ($A | index) as $ai |
  ($bi | keys)  as $bk | ($ai | keys) as $ak |
```
`$B`/`$A` are `--slurpfile` arrays of `{k, p, t}` records (line 215:
`jq -n --slurpfile B "$FLAT_B" --slurpfile A "$FLAT_A" "$JOIN_JQ"`). `t` is the flattened tag map
`{normkey: {n, v}}` built by `FLATTEN_JQ` (lines 126-142) — so "flattened tag maps differ" is a
comparison of `.t` across the records of one `group_by(.k)` group. `dupgroups` already has the
`group_by(.k)` shape to extend: an AMBIGUOUS group is one where `(map(.t) | unique | length) > 1`;
an identical duplicate collapses (`unique | length == 1`) and must not fire. Apply to **both**
`$B` and `$A` (D-11 "symmetric").

**Existing exit contract to extend** (header lines 26-32; usage line 72; exit block lines 295-300;
JSON arm lines 217-222):
```bash
# EXIT CODES (the contract Phase 7 gates on):
#   0  no net metadata loss - MISSING_AFTER is 0 AND FIELDS_DROPPED is 0
#   1  loss detected        - either is non-zero
#   2  usage or input error
```
```bash
if [[ $AS_JSON -eq 1 ]]; then
  printf '%s\n' "$RESULT"
  MISSING="$(jq -r '.counts.missing_after'  <<< "$RESULT")"
  DROPPED="$(jq -r '.counts.fields_dropped' <<< "$RESULT")"
  [[ "$MISSING" -eq 0 && "$DROPPED" -eq 0 ]] && exit 0 || exit 1
fi
```
⚠ **The `--json` arm has its own exit decision** and must get the exit-3 arm too, or `--json`
callers keep the silent last-wins behaviour.

**Where exit 3 sits in the ladder — copy the order from `check-music-consumers.sh`** (lines
1689-1741): the ordering there is `--baseline → 0`, `FAILURES>0 → 1`, `PENDING>0 → 3`, then green.
For this script the D-11 semantics are **UNKNOWN** (could not look), not "pending", and CONVENTIONS
§1 says could-not-look outranks a measured red elsewhere in the estate (`phase06-oracle.sh`: "UNKNOWN
outranks RED in this file's precedence", comment near line 3069). Decide and **state in the header**
which of 1 and 3 wins when both hold; whichever is chosen, the green line at 295-297 must stay
unreachable while AMBIGUOUS > 0.

**Informational-duplicates block to reword** (lines 267-276): it currently says "This does not
affect the exit code." — that sentence becomes false for divergent groups and must be corrected in
the same edit (retraction-in-place style, see beets.yaml lines 101-104).

**Summary block** (lines 278-292): add AMBIGUOUS_BEFORE / AMBIGUOUS_AFTER beside
`MATCHED`/`MISSING_AFTER`. Keep the existing vacuity counter (`matched_with_no_before_fields`, lines
287-292) — CONTEXT § code_context says it "must be read, not just the exit code".

**Scratch-file rule, keep** (lines 103-112): scratch goes beside BEFORE, never `/tmp` (LXC 100
`/tmp` is tmpfs — memory note `lxc100-tmp-is-tmpfs`). Fixtures for the self-test must follow it.

---

### `scripts/diff-music-tags.sh` — D-12 `--self-test` (test harness, batch)

**Analog:** `scripts/check-beets-config.sh` `run_self_test()` (lines 735-876); flag parsed at line
169 (`--self-test) SELFTEST_MODE=1 ;;`), dispatch at lines 878-879.

**Announced-vs-actual count pattern** (lines 736-745, 866-876):
```bash
run_self_test() {
  local ST_PLANNED_CASES=7
  echo "🧪 --self-test — $ST_PLANNED_CASES cases: 6 synthetic dumps, plus the D-04 contract over this file's own source"
  ...
  local st_failures=0 st_cases=0 st_red_cases=0
  ...
  if [[ $st_cases -ne $ST_PLANNED_CASES ]]; then
    echo -e "${RED}❌ --self-test: $st_cases cases ran but $ST_PLANNED_CASES were announced — the banner and the body disagree${NC}"
    return 1
  fi
  if [[ $st_failures -gt 0 ]]; then
    echo -e "${RED}❌ --self-test: $st_failures of $st_cases cases did not behave as expected${NC}"
    return 1
  fi
  echo -e "${GREEN}✅ --self-test: all $st_cases cases behaved as expected ($st_red_cases of them red)${NC}"
  return 0
}

if [[ $SELFTEST_MODE -eq 1 ]]; then
  if run_self_test; then exit 0; else exit 1; fi
```
**Per-case pattern to copy** (`run_case`, lines 752-770): name + expected outcome + input; compare
observed against expected; increment `st_cases`; count reds separately. For D-12 the two required
cases are: identical duplicate pair → expect exit **0** (must NOT fire); divergent pair → expect
exit **3** (MUST fire). Add a third case per convention 8.3 — a divergent pair on the **AFTER** side
— because D-11 is symmetric and an AFTER-only fixture is what proves `$ai` is covered.

⚠ `ST_PLANNED_CASES` is a **pinned count** (CONVENTIONS §5: listed for `check-beets-config.sh` and
`phase06-oracle.sh`). Adding a third instance means adding it to CONVENTIONS §5's list in the same
commit.

**Smaller alternative analog:** `phase06-oracle.sh` `st_case` (lines 1764-1772) — the
expectation/observed one-liner, if a lighter harness is preferred.

**Fixture shape:** NDJSON records matching `snapshot-music-tags.sh` `emit_record` (lines 193-207):
```bash
    '{audio_md5:   $audio_md5,
      source_path: $source_path,
      scan_root:   $scan_root,
      size_bytes:  $size_bytes,
      mtime_epoch: $mtime_epoch,
      ffprobe:     .}'
```
Only `audio_md5`, `source_path` and `ffprobe.format.tags` / `ffprobe.streams[].tags` are read by
`FLATTEN_JQ`, so fixtures can be minimal.

**D-12's real-data half:** run the changed diff over the existing QUAL-01 snapshot
(`/mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz`, from `snapshot-music-tags.sh`
lines 76-77 + `BASENAME="pre-project"` line 98) against itself. Record the AMBIGUOUS_BEFORE count;
it is the first non-synthetic reading.

---

### `scripts/check-music-import.sh` — NEW (health check, batch read)

**Primary analog (script skeleton, exit ladder, summary anchor):** `scripts/check-music-consumers.sh`.

**Header contract to copy** (lines 92-107):
```bash
# EXIT-CODE CONVENTION (inherited verbatim from scripts/check-music-freeze.sh:31-42, which is
# where the estate's convention was established; there was none before it):
#   default mode  - every red finding increments FAILURES and the script ends non-zero.
#   --baseline    - every finding is printed and the script always ends zero, so the before-state
#                   can be recorded while the mount and the provider do not yet exist.
#   usage error   - exit 2, distinct from exit 1 for a failed assertion.
#   pending       - exit 3. MEASURED, BUT NOT AT TARGET; NEVER GREEN.
```
For this script exit 3 means **UNKNOWN / vacuous** (D-25: "a zero count is `UNKNOWN` and fatal").
State the semantics in the header; do not reuse "pending" wording.

**Counters and helpers** (lines 564-578):
```bash
FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
```
`warn()` touches no counter — the exact trap CONVENTIONS §1 names. Every vacuity finding must set a
counter that the exit ladder reads.

**Summary heading — cross-file grep anchor** (lines 1646-1660):
```bash
# 6. Summary
#    KEEP THIS HEADING LITERAL AND NEVER RENUMBER IT SILENTLY. Plan 02-09's fold-in anchors on it
#    with `sed -n '/^📊 6\. Summary/,$p'`, ...
echo "📊 6. Summary"
```
Pick a literal `📊 N. Summary` for the new script, write the KEEP THIS HEADING LITERAL comment, and
the `quick-health-check.sh` fold-in anchors on it (CONVENTIONS §11).

**Exit ladder, order load-bearing** (lines 1689-1741):
```bash
if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "${YELLOW}--baseline: $FAILURES findings recorded, exiting 0. This is the before-state.${NC}"
  exit 0
fi

if [[ $FAILURES -gt 0 ]]; then
  echo -e "${RED}❌ $FAILURES failed checks${NC}"
  exit 1
fi
...
  exit 3
fi

# Reachable ONLY when FAILURES is 0 AND no artist row is pending.
echo -e "${GREEN}✅ Both music consumers see the pinned albums through the NFS export${NC}"
```

**Class 1 predicate (`.N` collision suffix) — reuse verbatim:** `phase06-oracle.sh`
`assert_no_collision_suffix` (lines 1104-1122):
```bash
  LC_ALL=C awk -F/ '{ b = $NF; if (b ~ /\.[0-9]+\.[^.\/]+$/) printf "COLLISION-SUFFIX\t%s\n", $0 }' "$dest" > "$ev"
```
Its own comment already names this sweep: "Phase 7's criterion 7 sweep exists to hunt these".
⚠ Drive it against a control (convention 8.3 / `DEF-06-45-04`) — and note the regex will also match
a legitimate `Op.64.flac`-style title; the control should include one such near-miss so a false
positive is characterised, not discovered.

**Atlantis-side library scan — shape to copy:** `quick-health-check.sh` underscore-dir guard
(lines 2771-2821). It is the only existing block that reads the library tree from atlantis:
```bash
MUSIC_UNDERSCORE_HOST="${MUSIC_UNDERSCORE_HOST:-root@172.16.1.158}"
MUSIC_UNDERSCORE_ROOT="${MUSIC_UNDERSCORE_ROOT:-/mnt/tank/media/Music}"
MUSIC_UNDERSCORE_ROOT_Q=$(printf '%q' "$MUSIC_UNDERSCORE_ROOT")
if [ "$MUSIC_UNDERSCORE_HOST" != "root@172.16.1.158" ]; then
    echo "⚠️  MUSIC_UNDERSCORE_HOST override in effect — this run cannot report the library guard green"
    EXIT_CODE=1
fi
...
UNDERSCORE_OUT=$(ssh -n $SSH_OPTS "$MUSIC_UNDERSCORE_HOST" "set -o pipefail; timeout $REMOTE_TIMEOUT find $MUSIC_UNDERSCORE_ROOT_Q -type d -name '_*' | wc -l")
UNDERSCORE_RC=$?   # ssh propagates the remote status — NO local pipe above, see the note above
UNDERSCORE_COUNT=$(printf '%s' "$UNDERSCORE_OUT" | tr -d '[:space:]')
if [ "$UNDERSCORE_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — the library scan exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    ...
elif [ "$UNDERSCORE_RC" -ne 0 ] || ! echo "$UNDERSCORE_COUNT" | grep -qE '^[0-9]+$'; then
    echo "⚠️  UNKNOWN — could not scan $MUSIC_UNDERSCORE_ROOT on $MUSIC_UNDERSCORE_HOST"
    ...
elif [ "$UNDERSCORE_COUNT" -gt 0 ]; then
    echo "❌ $UNDERSCORE_COUNT '_'-prefixed director(y|ies) under $MUSIC_UNDERSCORE_ROOT"
```
The comment block above it (lines 2735-2749) states both halves of the pipe rule and why a
**zero-truth check must be driven red once** (its "DRIVEN NEGATIVE CONTROL" paragraph, lines
2758-2769, is the template for D-25's "driven against a control first").

**Classes 2 and 3 (`mb_albumid` empty; track count vs `tracktotal`) — data-source decision:**
- Reading them from `library.db` means a `beet ls`/`beet` call against the **real** library, which
  D-04 forbids for anything but flask's 2.12.0 and which D-27 requires be compliant or **registered in
  `D04_EXEMPT_RE`** (see the D-04 block below). A read-only `sqlite3 'file:…?mode=ro'` on atlantis
  avoids a `beet` invocation entirely but reads a live DB file under a running writer.
- Reading them from files (ffprobe) avoids the DB but loses beets' view.
- Nearest precedent for `tracktotal` grouping and its first-wins trap:
  `scripts/phase05-now-tag-inventory.sh` lines 236 and 504-516 (`($tags.tracktotal // $tags.totaltracks)`,
  and the comment "First-wins therefore lets a single intruder's tracktotal set the expectation").
  That script is a Phase 5 inventory, not a sweep — D-25 confirms none of the three Phase-5 hits is a
  post-import sweep.

**Credential rule if the sweep calls any API:** copy `jf_api`/`ma_api` (see consumers section).

---

### `scripts/quick-health-check.sh` — D-25 fold-in block (aggregator, request-response)

**Analog:** the Music consumers fold-in, lines 2516-2715. Copy its whole skeleton:

**Override knob + `_Q` render** (knob declared near the other knobs, lines 912-926; rendered at the
block, lines 2524-2531):
```bash
CONSUMERS_SCRIPT="${CONSUMERS_SCRIPT:-/mnt/fast/stacks/scripts/check-music-consumers.sh}"
...
echo -n "Music consumers audit: "
CONSUMERS_OVERRIDDEN=0
if [ "$CONSUMERS_SCRIPT" != "/mnt/fast/stacks/scripts/check-music-consumers.sh" ]; then
    CONSUMERS_OVERRIDDEN=1
fi
CONSUMERS_SCRIPT_Q=$(printf '%q' "$CONSUMERS_SCRIPT")
CONSUMERS_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 \
    "timeout $REMOTE_TIMEOUT bash $CONSUMERS_SCRIPT_Q 2>&1")
CONSUMERS_RC=$?   # ssh propagates the remote exit status — do NOT pipe before capturing this
CONSUMERS_OUT=$(printf '%s\n' "$CONSUMERS_OUT" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')
```
Its knob comment (lines 912-925) carries the `⛔ DO NOT REUSE` paragraph — a new
`IMPORT_SWEEP_SCRIPT` knob must be its own knob, not a reuse of `CONSUMERS_SCRIPT` or any
`*_REPO_ROOT` (CONVENTIONS §4 last paragraph).

**Arm order (house S1 order)** — empty-output-not-124 → 124 → 0 → 3 → else (lines 2560, 2575,
2590, ~2640, 2706):
```bash
if [ -z "$CONSUMERS_OUT" ] && [ "$CONSUMERS_RC" -ne 124 ]; then
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the audit produced no output"
    ...
    EXIT_CODE=1
elif [ "$CONSUMERS_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — the remote audit exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    ...
    EXIT_CODE=1
elif [ "$CONSUMERS_RC" -eq 0 ]; then
    SUMMARY=$(echo "$CONSUMERS_OUT" | sed -n '/^📊 6\. Summary/,$p' \
              | grep -E 'MA version|albums matched in MA|albums matched in Jellyfin|FAILURES total')
    if [ -z "$SUMMARY" ]; then
        echo "⚠️  UNKNOWN — the audit exited 0 but its '📊 6. Summary' block was not found."
        ...
        EXIT_CODE=1
    elif [ "$CONSUMERS_OVERRIDDEN" -eq 1 ]; then
        echo "⚠️  CONSUMERS_SCRIPT override in effect — this run cannot report the consumers green"
        ...
        EXIT_CODE=1
    else
        ...green...
```
Every non-green arm carries the GC-14 override notice (a pure `echo`, never touching `EXIT_CODE`
beyond what the arm already sets — see the GC-14 comment, lines 2540-2557).

**Mandatory same-commit companions for a new fatal block:**
1. **A new `EXIT-CODE BEHAVIOUR CHANGED AGAIN` notice** at the top of the file. Template: the
   seventh-block notice (lines 383-427) — "THIS IS THE NTH SUCH NOTICE", BLOCK ordinal moves, "WHAT
   IT ASSERTS", "WHAT NOW EXITS THIS SCRIPT 1 THAT DID NOT BEFORE" with could-not-look split out.
   Count the headers with the bracketed recipe (lines 597-599), **never** a raw count:
   ```
   /usr/bin/grep -c '^# ⚠️  EXIT-CODE BEHAVIOUR CHANGE[D]' scripts/quick-health-check.sh
   ```
   Find the next free condition letter with `grep -nE '^#[[:space:]]+[A-Z]\.[[:space:]]'` (lines
   617-621 explain why counting forward is wrong).
2. **The failure tail** (lines 3100-3146) must name the new block. Its GC-09 paragraph (lines
   3107-3127) requires re-running the mechanical `EXIT_CODE=1` enumeration recorded in
   `artifacts/06-26-qhc-knobs-and-tail.txt` rather than eyeballing.
3. The header's `grep -n 'timeout \$REMOTE_TIMEOUT.*|'` house rule (lines 765-770): any new remote
   string with a `|` needs `set -o pipefail` in it.

⚠ `DEF-06-39-05`: this file has been executed **zero** times across rounds 3-6. The plan that edits
it should run it end-to-end at least once, and `DEF-06-29-01` warns that adding `set -euo pipefail`
to it arms six latent `| grep -q` inversions — **do not** add it.

---

### `scripts/quick-health-check.sh` — D-23 standing "`/media` is deliberately `rw`" assertion (health check, docker inspect)

**Analog:** the D-03 block's flask runtime arm (lines 1717-1783) — this is the **coupling C5 site**;
D-23 inverts it rather than adding a parallel block.

**Override guard shape** (lines 1718-1729):
```bash
D03_OVERRIDDEN=0
if [ "$D03_FLASK_CONTAINER" != "beets-flask" ] \
   || [ "$D03_BEETS_CONFIG_SOURCE" != "/mnt/fast/appdata/arrs/beets/config/config.yaml" ] \
   ...
   || [ "$D03_CLI_PROFILE" != "manual" ]; then
    D03_OVERRIDDEN=1
    echo "  ⚠️  a D03_* override is in effect — this run cannot report the mounts green"
    EXIT_CODE=1
fi
```
**The mount-flag read — no pipe in the remote string, matching done locally** (lines 1738-1753):
```bash
D03_FLASK_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 "timeout $REMOTE_TIMEOUT docker inspect $D03_FLASK_CONTAINER_Q --format '{{range .Mounts}}{{.Source}} {{.Destination}} {{.RW}}
{{end}}'")
D03_FLASK_RC=$?   # ssh propagates the remote status — NO local pipe above
D03_FLASK_LINES=$(printf '%s\n' "$D03_FLASK_OUT" | grep -c '^/')
if [ "$D03_FLASK_LINES" -eq 0 ] && [ "$D03_FLASK_RC" -ne 124 ]; then
    echo "  ⚠️  UNKNOWN — 'docker inspect $D03_FLASK_CONTAINER' returned no mount lines (ssh exit $D03_FLASK_RC)."
    echo "  Nothing was asserted. This is NOT 'no bad mounts' — an empty inspect must never satisfy a zero-test."
    EXIT_CODE=1
elif [ "$D03_FLASK_RC" -eq 124 ]; then
```
**The arm D-23 replaces** (lines 1774-1783):
```bash
    D03_F_MEDIA=$(printf '%s\n' "$D03_FLASK_OUT" | awk -v s="$D03_MEDIA_SOURCE" '$1==s {print $3}')
    if [ -z "$D03_F_MEDIA" ]; then
        echo "  ❌ $D03_FLASK_CONTAINER has NO mount from $D03_MEDIA_SOURCE — D-05 cannot be asserted from this runtime"
        EXIT_CODE=1
        D03_BAD=$((D03_BAD + 1))
    elif [ "$D03_F_MEDIA" != "false" ]; then
        echo "  ❌ D-05 VIOLATED — $D03_FLASK_CONTAINER holds $D03_MEDIA_SOURCE at RW=$D03_F_MEDIA, expected RW=false"
```
and the CLI-render arm (lines 1834-1841, `❌ D-05 VIOLATED — the dormant CLI arm declares …, expected ro`).
D-23 flips the expectation to `true`/`rw` **with the owning phase named in the pass line and the
comment** ("deliberately `rw` from Phase 7, D-22/D-23"). Keep the "no mount at all" arm as a red.
Keep the retracted D-05 prose visible as a dated retraction (house style — beets.yaml lines
101-104: "kept visible rather than deleted, per this repo's standing style for a retracted claim").
Also update the D-05 comment at lines 1706-1708 and header paragraph at line 456.

⚠ D-23's own caveat applies: CONVENTIONS §4 "A rule enforced by policy is weaker than one enforced
by mechanism" — say so at the site.

---

### `scripts/quick-health-check.sh` — D-27 exemption register (static scan)

**Analog:** the D-04 block, lines 1935-2140. Knobs declared at lines 898 and 911.

**Pins:**
```bash
D04_DOC_BASELINE="${D04_DOC_BASELINE:-2}"
...
D04_EXEMPT_BASELINE="${D04_EXEMPT_BASELINE:-5}"
```
**Override guard** (lines 1996-2000):
```bash
if [ "$D04_EXEMPT_BASELINE" != "5" ]; then
    D04_OVERRIDDEN=1
    echo "  ⚠️  D04_EXEMPT_BASELINE override in effect — this run cannot report D-04 green"
    EXIT_CODE=1
fi
```
**The register — keyed on file path AND a distinguishing token** (line 2066):
```bash
    D04_EXEMPT_RE='^HEAD:scripts/phase06-oracle\.sh:[0-9]*:.*\$SCRATCH_OVERLAY|^HEAD:scripts/phase06-incremental-control\.sh:[0-9]*:.*\$ROOT/overlay\.yaml'
```
**Its reason-in-full comment** (lines 1935-1960, "THE EXEMPTION REGISTER, AND ITS REASON IN FULL…")
is the template for any new entry: three numbered reasons that must all hold, plus
"⛔ THE EXEMPTION IS NOT A SKIP."

**What the scan matches** (`D04_INV_RE`, line 2062) includes `docker[[:space:]][^`]*[[:space:]]beet[[:space:]]`
— so **D-08's `docker exec … beet modify` / `beet move` lines in any script under `scripts/` or
`stacks/` WILL be counted** and must be either compliant (`-l` not `/config/library.db` AND `-c`) or
registered. A D-08 call against the real library cannot be compliant by construction, so it must be
**registered**, and `D04_EXEMPT_BASELINE` then moves in the **same commit** as the new lines
(CONVENTIONS §5 remedy). The D-27 prohibition is on raising the pin **to make a run green without a
registered reason** — not on moving it with a registered entry. `D04_DOC_BASELINE` (runbook prose
in `*.md`) must **not** move: 06-16 rephrased prose rather than raise it.

**Overlay-key half, "drive both ways" (D-27, `DEF-06-21-06`):** the exempt set is selected by
`grep -E "$D04_EXEMPT_RE"` (line 2070). Driving it both ways = one invocation line in an exempt file
**without** the overlay token (must land in `D04_INVOKE_ASSERT` and go red) and one **with** it
(must land in `D04_INVOKE_EXEMPT`). `D04_REPO_ROOT` (line 902) is the sanctioned knob for driving
it against a scratch checkout; any non-default value forces `EXIT_CODE=1`.

---

### `scripts/check-music-freeze.sh` — coupling C6 (health check, docker inspect)

**Analog:** its own consumer-exception arm (lines 1036-1046):
```bash
    while IFS='|' read -r cname cstate csrc cdst cflag; do
      [[ -z "${cname:-}" ]] && continue
      [[ "${cflag:-ro}" != "rw" ]] && continue
      census_reaches_library "${csrc:-}" || continue
      if [[ "$cname" =~ $CONSUMER_PATTERN ]]; then
        RW_JELLYFIN=$((RW_JELLYFIN + 1))
        info "rw on Music, D-21 consumer exception: $cname [$cstate] $csrc:$cdst"
        continue
      fi
      if printf '%s\n' "$ALL_TAGGER_NAMES" | grep -qxF "$cname"; then
        RW_TAGGER=$((RW_TAGGER + 1))
        fail "rw on Music: $cname [$cstate] $csrc:$cdst (tagger-capable)"
```
The mount-row format the orchestrator asked about (lines 1004-1006):
```bash
    ALL_ROWS="$(docker inspect --format \
      '{{$n := .Name}}{{$s := .State.Status}}{{range .Mounts}}{{$n}}|{{$s}}|{{.Source}}|{{.Destination}}|{{if .RW}}rw{{else}}ro{{end}}{{"\n"}}{{end}}' \
      $ALL_IDS 2>/dev/null | sed 's#^/##' | grep -v '^[[:space:]]*$' || true)"
```
(`name|state|source|destination|rw-flag`, `|`-separated because `:` is ambiguous in compose
mappings — comment at lines 342-344.) A named Phase-7 tagger exception should be counted on **its
own line** in the summary (line 1121 is the precedent: "excluding the D-21 consumer exception") and
be exactly one named container, not a pattern that could admit a second.

---

### `scripts/check-music-consumers.sh` — D-24 30-item reading and D-28 `%aunique{}` MA check (request-response)

**Analog:** itself.

**Secrets: mode-600 gate, no `set -a`** (lines 745-778):
```bash
if [[ -r "$JELLYFIN_SECRETS" ]]; then
  JF_MODE="$(stat -c '%a %U' "$JELLYFIN_SECRETS" 2>/dev/null || echo '? ?')"
  if [[ "$JF_MODE" == "600 root" ]]; then
    pass "Jellyfin credential $JELLYFIN_SECRETS ($JF_MODE)"
    # shellcheck disable=SC1090
    . "$JELLYFIN_SECRETS"    # no `set -a`: in-process only
  else
    fail "Jellyfin credential $JELLYFIN_SECRETS has mode/owner '$JF_MODE', want '600 root' (D-40) — REFUSING"
```
Paths: `MA_SECRETS="/mnt/fast/secrets/ma-deercrest.env"`, `JELLYFIN_SECRETS="/mnt/fast/secrets/jellyfin-deercrest.env"` (lines 291-292).

**Jellyfin call — key via process substitution, never argv** (lines 682-690):
```bash
jf_api() {
  local path="$1"; shift
  curl -s --max-time 20 -G \
    -H @<(printf 'Authorization: MediaBrowser Token="%s"\n' "$JELLYFIN_API_KEY") \
    "http://${JELLYFIN_ADDR}${path}" "$@" || true
}
```
**MA login + call** (lines 621-665):
```bash
  body="$(MA_USERNAME="$MA_USERNAME" MA_PASSWORD="$MA_PASSWORD" jq -nc \
          '{command:"auth/login",args:{username:$ENV.MA_USERNAME,password:$ENV.MA_PASSWORD}}')"
  resp="$(printf '%s' "$body" | curl -s --max-time 20 -X POST "${MA_URL}/api" \
          -H 'Content-Type: application/json' --data-binary @- || true)"
  # NOT .result.access_token - see API SHAPE NOTE 1.
  MA_TOKEN="$(printf '%s' "$resp" | jq -r '.access_token // empty' 2>/dev/null || true)"
```
```bash
  printf '%s' "$body" | curl -s --max-time 30 -X POST "${MA_URL}/api" \
    -H 'Content-Type: application/json' \
    -H @<(printf 'Authorization: Bearer %s\n' "$MA_TOKEN") --data-binary @- || true
```
**Provider filter — never let it be empty** (`provider_filter`, lines 667-678): "an empty `provider`
would silently drop the filter and let Spotify answer". CONTEXT also records that
`music/albums/count` **silently ignores** its `provider` argument.

**`ARTIST_PROOF_ROWS` row format** (lines 495-543): `path|target|jf_baseline|ma_baseline|tagpos|search|why`.
Row 1's comment already states the D-24 fact: "30 of the 1,244 items are like this. Asserting on
`Artists` instead of `ArtistItems` would read green here." A second ≥4-artist track (D-05) becomes
a **new row** in this array.

**Per-item read to copy for D-24** (section 4b, lines 1340-1372):
```bash
    JFA="$(jf_api /Items \
      --data-urlencode "IncludeItemTypes=Audio" \
      --data-urlencode "Recursive=true" \
      --data-urlencode "ParentId=${JELLYFIN_MUSIC_LIBRARY_ID}" \
      --data-urlencode "SearchTerm=${ASEARCH}" \
      --data-urlencode "Fields=ArtistItems,Artists,Path")"

    if ! printf '%s' "$JFA" | jq -e 'has("Items")' >/dev/null 2>&1; then
      jellyfin_fail "CONF-04: no Items envelope for '$ASEARCH' — UNKNOWN, not green"
      continue
    fi
    ITEM="$(printf '%s' "$JFA" | jq -c --arg p "$APATH_I" \
      '[.Items[] | select(.Path == $p)] | .[0] // empty')"
```
For the 30-item census drop `SearchTerm` and select `(.Artists|length)>0 and ((.ArtistItems//[])|length)==0`
over the whole library — one call, as CONTEXT D-24 says. Record the count **before** and **after**
the pilot writes.

**Pending-vs-fail three-way branch** (lines 1386-1418) is the shape for D-28: at target → `pass`;
at recorded baseline → pending counter (exit 3); anything else → `jellyfin_fail`/`ma_fail`
"something changed that nobody planned".

**Cross-file constraints when editing this file:**
- The `📊 6. Summary` heading (line 1659) and the `Discharges on ROADMAP` phrase (line 1738, ≤ 8-line
  block) are anchors read by `quick-health-check.sh` lines 2598, 2671-2690. Keep both.
- The final green line (line 1746) "Text is byte-frozen".
- Fold-in greps the summary for `'MA version|artist rows|FAILURES total'` (line 2672): new summary
  lines should not collide with those labels unintentionally.
- **Do not use the FullRefresh / "Replace all metadata" route anywhere** (CONTEXT § Carried).
- Resolve Jellyfin's container address fresh (`JELLYFIN_ADDR` set at runtime, never a literal).

---

### `stacks/selfhosted/arrs/beets/config.yaml` — D-22 (config)

**Analog:** its own `import:` stanza, verbatim (lines 299-339):
```yaml
# --------------------------------------------------------------------------------
# CONF-01 / CONF-02 — import behaviour
# --------------------------------------------------------------------------------
import:
    # CONF-01. THERE IS NO `beet undo` — verified against the live CLI, not assumed. A bulk run
    # over the 97 GB backlog with `move` set CONSUMES ITS OWN SOURCE, and the only reversal is a
    # ZFS rollback of two datasets. `tank` has 9 T free, so the duplication `copy` costs is
    # affordable and, unlike `move`, reversible by deleting the destination.
    # rc6 additionally TYPE-enforces these two as `Literal[True]` / `Literal[False]`, so a config
    # setting `move: yes` is REJECTED at validation rather than overridden. ...
    copy: yes
    move: no

    # CONF-02 — AND THESE TWO KEYS TRAVEL TOGETHER. ...
    incremental: yes
    incremental_skip_later: yes

    # rc6's schema default for this key is `remove` — WHICH DELETES THE DUPLICATE WITH NO PROMPT. ...
    duplicate_action: ask

    # Phase 7 behaviour, set here so it is a stated fact rather than an inherited one.
    # ⚠ EVERY PHASE 6 INVOCATION OVERRIDES THIS TO `no` THROUGH A `-c` OVERLAY. Phase 6 writes
    # nothing to any audio file; the overlay, the `:ro` mount (D-05) and the statefile sha256
    # (D-29) are three independent expressions of that, and this key is deliberately NOT one of
    # them — a phase that depended on this line being right would be one edit from writing.
    # The D-18 register below is what a `write: yes` import is required not to damage.
    write: yes
```
- **Coupling C1:** `copy: yes` / `move: no` is already committed. D-22 item 2 is therefore a
  *verification* of the repo **and** the appdata copy, not an edit.
- Stale in-band figure: "`tank` has 9 T free" (line 305) — CLAUDE.md records the 5.26 T correction.
  If the plan touches this stanza it should correct it (CONTEXT § Deferred: correct stale figures
  "where a plan already touches that file"). Re-measure before writing.
- D-22 item 3 — the `write: yes` comment (lines 332-339) is where "the bound is D-21 (`01-auto`
  de-registered)" is recorded, and where "FORCED, not chosen — criterion 3 needs `ffprobe` to see the
  new tags on the file" is stated. The existing "the `:ro` mount (D-05)" clause becomes a dated
  retraction.
- `duplicate_action: ask` — relevant to D-04's Benson Boone pair (run 1 silently dropped ten files
  under `skip`).
- `%aunique{}` settings (lines 294-297) and the numeric-ID landmine comment (lines 283-287) bear on
  D-28 and on D-07's frozen oracle rows.

**`paths:` stanza verbatim** (lines 206-236) — **locked** (CONTEXT § Carried; do not edit):
```yaml
paths:
    singleton:                      'Singles/$artist/$title%sunique{}'
    'albumtype:=dj disctotal:2..':  'DJ/$albumartist/$album%aunique{}/$disc-$track $title'
    'albumtype:=dj':                'DJ/$albumartist/$album%aunique{}/$track $title'
    'disctotal:2..':                '$albumartist/$album%aunique{}/$disc-$track $title'
    comp:                           '$albumartist/$album%aunique{}/$track $title'
    default:                        '$albumartist/$album%aunique{}/$track $title'
```
(Each rule carries a numbered comment in the file; rule 2 is D-09's read-only class assertion
target. `per_disc_numbering: yes`, line 250, is what makes `$disc-$track` render `02-05`.)

---

### `stacks/selfhosted/arrs/beets/beets.yaml` and `flask.yaml` — `:ro` → `:rw` (compose config)

**Current volume lines:**
- `beets.yaml` line 116: `      - /mnt/tank/media:/media:ro  # Existing library — READ-ONLY for all of Phase 6; rw is Phase 7's first act`
- `flask.yaml` line 161: `      - /mnt/tank/media:/media:ro`

**Comment style to copy — dated retraction kept visible** (`beets.yaml` lines 101-115):
```yaml
      # CORRECTED 2026-09-20, plan 06-04, D-05. The third sentence above — "Phase 3 chooses the
      # one tagger and Phase 6 grants it rw" — IS WRONG. It is kept visible rather than deleted,
      # per this repo's standing style for a retracted claim (beets.md:70-77, "Stated as
      # retractions, not quiet replacements"). The correct statement:
```
The `flask.yaml` D-05 block (lines 147-160) says "If you flip this to :rw to 'just run one import',
you have re-created the exact failure…" — the Phase-7 edit must answer that sentence in band (the
fence is in place, the decision is D-22/D-23), not delete it.

**Readiness gate after `docker compose up -d` (both files):** `beets.yaml` lines 84-91 — gate on
`docker exec -u abc … test -r /config/config.yaml`, never `.State.Status`; `flask.yaml` lines
213-227 — gate on the watchdog line `Registering watchdog … for inboxes: [...]` (coupling C4: the
expected count becomes **two**).

---

### `stacks/selfhosted/arrs/beets/flask-config.yaml` — D-21 de-registration, C3 (config)

**Analog:** its own `folders:` block (lines 76-104):
```yaml
    folders:

      # Bucket A — mainstream releases that should autotag cleanly. `auto` imports without asking
      # when the match clears the threshold.
      "01-auto":
        name: "01-auto"
        path: /downloads/complete/nzb/_inbox/01-auto
        autotag: auto

      "02-review":
        name: "02-review"
        path: /downloads/complete/nzb/_inbox/02-review
        autotag: preview

      "03-asis":
        name: "03-asis"
        path: /downloads/complete/nzb/_inbox/03-asis
        autotag: bootleg
```
De-register by removing the `"01-auto"` mapping and leaving a dated comment in its place naming D-21,
E11 and "re-registered in Phase 8". The **directory stays** (D-21) — which matters because rc6's
`validate()` raises on a missing inbox path (lines 65-68), and the removed entry no longer needs it.
Also lines 115-118 already name the D-08 DJ-routing gap ("There is NO per-inbox `set_fields` … The DJ
routing mechanism for a real flask import is an UNOWNED GAP") — D-08 closes it; update in band.

**C3:** `library: readonly: true` (lines 123-129).

---

### `stacks/selfhosted/arrs/beets.md` — closure section + head pointer (doc)

**Head pointer blockquote** (lines 16-38) — the part any closure section must update in the same
commit:
```markdown
> The authoritative current state is the section headed
> *Phase 6 closed 2026-09-21 — four criteria TRUE, one OPEN on a named half, all five RE-MEASURED at close*.
> Its verdict table is the sub-section headed *The five criteria* **under that heading** — the same
> sub-heading text also appears in the Phase 5 closure above it, so disambiguate by the parent — and
> what remains open is the sub-section headed *Still open at Phase 6 close*.
...
> **The go-forward rule, as a rule and not a hope:** every future phase-closure section appended to
> this file **must update this pointer in the same commit**. A closure section whose pointer was not
> updated is the defect — not the pointer.
```
Current last `##` heading: `## Phase 6 closed 2026-09-21 — four criteria TRUE, …` (line 2077);
its sub-sections `### The five criteria` (2093), `### Still open at Phase 6 close` (2233),
`### How to re-run the Phase 6 evidence` (2467). A Phase 7 section appends after it with the same
sub-section shape. `UNDO IMPORT` is already documented at lines 1056 and 1380 (D-14's source).

---

### `scripts/phase06-oracle.sh` — D-30 confirmation on the first real `--run` (test oracle)

**Analog:** itself. Modes (usage, lines 284-298): `--run | --baseline | --self-test`; exit
`0 = zero-diff and zero reds  1 = red  2 = usage/precheck  3 = UNKNOWN`.

**Sending-side fence (layer 1), validated before the first ssh** (lines 341-351):
```bash
SCRATCH_FENCE_OK=1
case "$SCRATCH" in
  /tmp/p6) : ;;
  /tmp/p6-*)
    case "${SCRATCH#/tmp/p6-}" in
      ''|*[!A-Za-z0-9._-]*) SCRATCH_FENCE_OK=0 ;;
    esac
    ;;
  *) SCRATCH_FENCE_OK=0 ;;
esac
[ "$SCRATCH_FENCE_OK" -eq 1 ] || precheck_fail "REFUSED: SCRATCH='$SCRATCH'.
```
**Receiving-side fence (layer 2), POSIX, concatenated in front of the destructive program**
(lines 1447-1456, 1485-1487):
```bash
SCRATCH_FENCE_SH='case "$1" in
  /tmp/p6) : ;;
  /tmp/p6-*)
    case "${1#/tmp/p6-}" in
      ""|*[!A-Za-z0-9._-]*)
        echo "REFUSED: the scratch path is not a throwaway root under /tmp/p6" >&2; exit 3 ;;
    esac
    ;;
  *) echo "REFUSED: the scratch path is not a throwaway root under /tmp/p6" >&2; exit 3 ;;
esac'
...
CLEANUP_PROG="$SCRATCH_FENCE_SH"'
rm -rf "$1"
[ -e "$1" ] && echo present || echo gone'
```
Path crosses as a positional parameter via `remote_sh_c` (lines 1369-1377) — `sh -c <%q prog> sh <%q arg>`.
"Refuses end to end under the container's `dash`" (D-30) = drive `CLEANUP_PROG` with a bad path
**inside the container** (`dex_cmd` + `remote_sh_c`), not with macOS `/bin/sh`. GC-11 note (lines
1356-1364): `$'…'` quoting of multi-line programs needs a **bash** transport on LXC 100's login shell;
the container `sh` is dash.

**`layer3.before` / `layer3.after` parse — the two awk keys D-30 confirms** (lines 2895-2901,
3056-3060):
```bash
rsh "$(dex_cmd sha256sum "$(printf '%q' "$REAL_LIB_DB")" "$(printf '%q' "$REAL_STATE_PICKLE")")"
rsh_classify "the layer-3 baseline hashes" || exit 3
printf '%s\n' "$RSH_OUT" > "$OUT/layer3.before"
LIB_SHA_BEFORE="$(LC_ALL=C p="$REAL_LIB_DB" awk '{ rest = $0; if (sub(/^[0-9a-f]+  /, "", rest) && rest == ENVIRON["p"]) print $1 }' "$OUT/layer3.before")"
STATE_SHA_BEFORE="$(LC_ALL=C p="$REAL_STATE_PICKLE" awk '{ rest = $0; if (sub(/^[0-9a-f]+  /, "", rest) && rest == ENVIRON["p"]) print $1 }' "$OUT/layer3.before")"
[ -n "$LIB_SHA_BEFORE" ] || { unknown "no sha256 line for $REAL_LIB_DB"; exit 3; }
```
**Remote helpers** (lines 1289-1340): `rsh`, `rsh_to`, `rsh_classify` (house S1 order: empty-not-124
→ 124 → non-zero → usable), `dex_cmd` (`timeout N docker exec -u USER CONTAINER …`, "NO PIPELINE
inside the container — its /bin/sh is dash and has no `pipefail`").

**No cleanup `trap` anywhere, deliberately** (CONVENTIONS §6 companion, `DEF-06-39-02`) — so D-30's
"no `/tmp/p6-mf.*` / `/tmp/p6-taghist.*` survives" is checked **after** the run, not guaranteed by a
trap. R4-10 (comment near line 3067) records which `exit 3` arms skip step 12.

⚠ **C7 / C8** — both break once the pilot writes. Sequence D-30's `--run` before D-22's deploy, or
plan an explicit, driven re-scope.

**D-30 rider — `arm1.dump`:** `scripts/check-beets-config.sh` lines 189 (`WORKDIR="$(mktemp -d)"`),
1011 (`cp "$WORKDIR/exec.out" "$WORKDIR/arm1.dump"`). Record `wc -c < "$WORKDIR/arm1.dump"` on the next
live run — the file is in a `mktemp -d`, so the size must be captured inside the run (or by a
one-line addition) rather than after.

---

### `scripts/snapshot-music-tags.sh` — AFTER capture (exercise only, file-I/O batch)

**The four pinned roots, verbatim** (lines 79-87):
```bash
# The four D-02 scan roots: ~9,736 audio files, ~140 GB, one full read. The library files are
# included despite re-importing them being out of scope, because a Phase 7 import writing to a
# colliding destination path can degrade them and they have no other recovery path.
DEFAULT_ROOTS=(
  "/mnt/tank/downloads/complete/nzb/unsorted"
  "/mnt/tank/downloads/complete/nzb/dj-mixes"
  "/mnt/tank/downloads/complete/nzb/music"
  "/mnt/tank/media/Music"
)
```
Output: `FENCE="/mnt/fast/safety/music-pre-project"`, `OUTDIR="${FENCE}/tags"` (lines 76-77);
`<BASENAME>.ndjson.gz / .done / .failed` (lines 165-167). Usage (line 12):
`bash scripts/snapshot-music-tags.sh [BASENAME] [--roots DIR[,DIR...]] [--limit N]`. An AFTER capture
of the pilot is a new BASENAME with `--roots` bounded to the twelve albums' library destinations; the
BEFORE side is the existing `pre-project` capture. `.done` makes it resumable (D-18).

---

## Plan-artifact shapes

### D-16 fence step — "the 06-41 pattern"

**Source:** `.planning/phases/06-tagger-configuration-and-dry-run/06-41-PLAN.md` Task 2 (lines
158-253) and its executed transcript `artifacts/06-41-conf04-reprobe-drive.txt` (lines 45-65,
250-270).

Action text to copy (06-41-PLAN.md lines 173-181):
```
    Run on atlantis (`root@172.16.1.158`). ONE remote step, in this order, so the fence and the
    mutation cannot come apart:

      1. `zfs snapshot tank/media/Music@pre-06-41-conf04-reprobe`. Then assert it exists by listing
         it back. If the snapshot command fails for any reason, STOP — do not touch anything. A
         mutation without its fence is the one shape this project's own reversibility rule forbids
```
Recorded form (drive artifact lines 55-58 and trace lines 266-270):
```
  command issued : zfs snapshot tank/media/Music@pre-06-41-conf04-reprobe
  exit status    : 0
  listed back    : tank/media/Music@pre-06-41-conf04-reprobe    (zfs list -t snapshot -H -o name, rc=0)
  (1) the snapshot listed back equals the name minted, exactly  -> PASS
```
```
+ zfs snapshot tank/media/Music@pre-06-41-conf04-reprobe
+ SNAP_RC=0
+ zfs list -t snapshot -H -o name tank/media/Music@pre-06-41-conf04-reprobe
+ SNAP_BACK_RC=0
```
Plus the delimited-block convention (06-41-PLAN.md lines 199-213): `--- ZFS DIFF BEGIN ---` /
`--- COMMAND TRANSCRIPT BEGIN ---`, with mechanical screens run **over the extracted block** (e.g.
`zfs destroy` count 0) — because prose discussing a token cannot be distinguished from the token.

**Two-dataset precedent in code:** `scripts/freeze-music-apply.sh` lines 139-150 (`zfs_exec`,
`snapshot_exists`) and 229-251 (two explicit `zfs snapshot` calls, "Two explicit invocations rather
than a loop … both dataset names should be readable without following a variable", then a
`snapshot_creation` read-back loop). Note it is **skip-if-exists**; D-16 wants **fail-if-exists**
(06-41's pre-gate asserted count `0` before minting — 06-41-PLAN.md line 152).

**D-16 hard fence, per CONVENTIONS §6 (duplicate at each call site):** `zfs rollback` on
`fast/appdata/arrs` is forbidden on every branch; recovery is a **file restore** out of
`/mnt/fast/appdata/arrs/.zfs/snapshot/pre-07-pilot/…`. Write the verb bracketed
(`zfs [r]ollback`) in any artifact that a detector counts — 06-52-PLAN.md line 300 pattern.

### D-19 snapshot register + prune gate — "the 06-52 shape"

**Source:** `.planning/phases/06-tagger-configuration-and-dry-run/06-52-PLAN.md`.
- Frontmatter: `autonomous: false` (line 13).
- **Scope fence paragraph** (lines 76-82): "The only `zfs` verb this plan may issue on any branch is
  **`zfs list`** … unless the operator explicitly answers `release`, in which case exactly one
  `zfs destroy` of exactly one named snapshot is permitted. **`zfs rollback` is forbidden on every
  branch**".
- **Task 1** `type="checkpoint:decision" gate="blocking"` (lines 106-249): "Measure first. Reason
  second. Ask third. Issue no write on any branch of this task." `MEASURED STATE` (a)-(e) via
  `zfs list -t snapshot -o name,used,refer,creation -r <dataset>`; **exact whole-line** presence test
  (`grep -qxF`); a `DEPENDENCY REASONING` section answering five questions with cited evidence; a
  stated recommendation; `<options>` with `hold` first; resume-signal "Any other answer is treated as
  `hold`" (line 213); acceptance criteria forbidding any write in the gate task.
- **Task 2** (lines 251-300): per-branch execution. On `release`: re-assert presence immediately
  before the act; exactly one `zfs destroy` naming one snapshot in full, no `-r`/`-R`/`-f`, fenced at
  the call site; re-list both datasets and compare full name sets; "`zfs list` can lag a large delete
  by ~20 s … judge on the name set, not on `avail`".
- Disposition mapping (lines 70-74): `hold`/`defer` → `CARRIED`, `release` → `FIXED`.

D-19 differs in scope (nine snapshots, one gate presenting the full list); the per-snapshot
eligibility test (a strictly newer sibling on the same dataset **and** a register row naming the
covered change) goes in `DEPENDENCY REASONING`. "none recorded" is written as a could-not-look
(`DEF-06-52-02`; CONVENTIONS §14).

### D-17 mechanical release of `@pre-06-41-conf04-reprobe`

Same act as 06-52 Task 2's `release` branch (re-assert, single fenced `zfs destroy`, re-list), but
triggered by the commit that records criterion 1 satisfied — **no gate**. `tank/downloads@pre-phase5`
stays untouched on every branch (06-52 scope fence).

### D-07 frozen oracle rows — CONVENTIONS §10

```
git show <commit>:.planning/phases/06-tagger-configuration-and-dry-run/06-EXPECTED-TREE.txt
```
Capture `BASE=$(git rev-parse HEAD)` before the first write; assert byte-identity of the six carried
lines by digest of `git show <base>:<path>` vs the working file, two hash implementations agreeing
(CONVENTIONS §10 canonical example: plan 06-48). Never `git diff --exit-code <path>` without `HEAD --`.

### D-31 evidence map; D-18 STOP state

No direct analog file. Nearest shape: 06-52's `MEASURED STATE` / `DEPENDENCY REASONING` headed
sections inside one `artifacts/*.txt`, and `06-VERIFICATION.md`'s per-criterion table. Counted tokens
in any artifact are **bracketed** and counted with `grep -cE` (CONVENTIONS §8.1).

---

## Shared Patterns

### Fail-closed, three states
**Source:** CONVENTIONS §1; `check-music-consumers.sh` exit ladder (lines 1689-1746).
**Apply to:** `diff-music-tags.sh`, `check-music-import.sh`, every new `quick-health-check.sh` arm.
Could-not-look is its own exit/arm, never a zero; the green line is placed where it is unreachable
while any UNKNOWN/pending counter is non-zero.

### Remote command bounding
**Source:** `quick-health-check.sh` `REMOTE_TIMEOUT` (line 776) and WR-08 comment (lines 738-775);
underscore guard (lines 2788-2790).
**Apply to:** every ssh in new/edited scripts.
```bash
OUT=$(ssh -n $SSH_OPTS root@172.16.1.158 "set -o pipefail; timeout $REMOTE_TIMEOUT <cmd> | <cmd>")
RC=$?   # ssh propagates the remote status — NO local pipe above
```
`SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=10"` (line 732). `ssh -n` so a nested ssh cannot eat
stdin. `bounded_ssh` (lines 1057-1078) is for **side-effect-free probes only** (its KNOWN LIMIT: kills
the client, not the remote command). Hosts: atlantis `root@172.16.1.158` (zfs, real-root ownership,
**no git**); LXC 100 `root@172.16.1.159` (docker, the deployed checkout at `/mnt/fast/stacks`,
secrets at `/mnt/fast/secrets/`). Any git-based check (e.g. D-04's `git grep … HEAD`) runs on LXC 100.

### Additive-only overrides
**Source:** CONVENTIONS §4; every `_OVERRIDDEN` guard in `quick-health-check.sh` (e.g. lines
1986-2000, 2779-2786).
**Apply to:** every new `${VAR:-default}` knob — one-line compare against the default, print
"override in effect — this run cannot report … green", `EXIT_CODE=1` unconditionally; render with
`printf '%q'` once (`*_Q`) and interpolate only the `_Q` form into remote strings; never share a knob
across two blocks.

### Pinned counts
**Source:** CONVENTIONS §5; `D04_EXEMPT_BASELINE`, `ST_PLANNED_CASES`.
**Apply to:** D-27 register, D-12 self-test. Move the pin in the **same commit** as the change that
moved the count, with the reason; never via the env override.

### Destructive fence, duplicated per site
**Source:** CONVENTIONS §6; `phase06-oracle.sh` `SCRATCH_FENCE_SH` / `CLEANUP_PROG`.
**Apply to:** D-16's `zfs rollback` prohibition on `fast/appdata/arrs`, D-17/D-19 `zfs destroy`
call sites, any `rm` the pilot scripts.

### Credentials
**Source:** CONVENTIONS §7; `jf_api`, `ma_api`, `ma_login` in `check-music-consumers.sh`.
**Apply to:** D-24, D-28, any sweep API call. `-H @<(printf …)`, `$ENV.NAME` for jq, secrets sourced
without `set -a` after a `stat -c '%a %U' == "600 root"` gate.

### Counted tokens and grep hygiene
**Source:** CONVENTIONS §8-9; `quick-health-check.sh` recipe block (lines 597-599).
**Apply to:** every published count in `artifacts/` and every acceptance recipe. `/usr/bin/grep` by
absolute path; bracketed needle ⇒ `-cE`, never `-cF`; comment-stripped form
`/usr/bin/grep -vE '^[[:space:]]*#' <file> | /usr/bin/grep -c <token>`; measure after writing;
drive a zero-expecting recipe against a positive control first.

### Byte identity
**Source:** CONVENTIONS §10.
**Apply to:** D-07, any "this file is untouched" acceptance criterion:
`git diff --exit-code HEAD -- <path>`, or a digest of `git show <BASE>:<path>` for whole-plan
immutability.

### In-band narrative
**Source:** CONVENTIONS §12.
**Apply to:** every comment added this phase — the *why* stays in the code, round history goes to
`.planning/phases/07-*/`, cited by one short ID. Retractions stay visible and dated.

---

## No Analog Found

| File / item | Role | Data Flow | Reason |
|-------------|------|-----------|--------|
| D-12 `--self-test` inside `diff-music-tags.sh` | test | batch | The script has **no self-test today** (`grep -n self-test scripts/diff-music-tags.sh` → no hits). Harness shape must be imported from `check-beets-config.sh`; there is no in-file precedent to extend. |
| D-08 `docker exec beets-flask beet modify albumtype=dj` + `beet move` | operation | CRUD on real library | No script in the repo issues a **writing** `beet` against the real `library.db`. Nearest: `phase06-oracle.sh` `dex_cmd` (read/throwaway only). Must be registered under D-27. |
| D-14 beets-flask rc6 `UNDO IMPORT` with `state.pickle` proof | operation | UI-driven | Only prose precedent (`beets.md` lines 1056, 1380). The proof instrument is `phase06-oracle.sh`'s layer-3 sha256 read of `state.pickle` (lines 2895-2901), reused as a before/after witness. |

---

## Metadata

**Analog search scope:** `scripts/` (all `.sh`), `stacks/selfhosted/arrs/beets/`, `stacks/selfhosted/arrs/beets.md`, `CONVENTIONS.md`, `.planning/phases/06-tagger-configuration-and-dry-run/` (06-41, 06-52 plans; 06-04, 06-41 artifacts; deferred-items.md)
**Files scanned:** 18
**Pattern extraction date:** 2026-09-25
