---
phase: 05-inbox-structure-and-the-junk-gate
mapped: 2026-09-18
type: patterns
inputs: [05-CONTEXT.md, 05-PREMEASURE.md, CLAUDE.md]
note: no RESEARCH.md for this phase (ROADMAP — "Research: not needed")
---

# Phase 5: Inbox Structure and the Junk Gate — Pattern Map

**Mapped:** 2026-09-18
**Artifacts classified:** 9 (6 scripts/script-changes, 3 markdown record changes)
**Analogs found:** 9 / 9 — every named analog in `05-CONTEXT.md` **exists at the stated path** and was read.
**Verified present:** `scripts/spike03-image-headroom.sh` (506 ln), `scripts/normalise-dj-tags.py` (1590 ln),
`scripts/quick-health-check.sh` (1818 ln), `scripts/snapshot-music-tags.sh` (400 ln),
`scripts/diff-music-tags.sh` (300 ln), `scripts/freeze-music-apply.sh` (646 ln).
**No named analog was missing.** One *unnamed* gap is recorded in § No Analog Found.

This is an infrastructure / shell-scripting phase. There are no components, routes, models or
endpoints. Classification below uses `role` = the estate's script taxonomy and `data flow` = what
the artifact actually moves.

---

## File Classification

| New/Modified artifact | Role | Data flow | Closest analog | Match quality |
|---|---|---|---|---|
| `scripts/phase05-junk-sweep.sh` (new; D-11/D-12/D-13) | two-process approval gate | enumerate → file → act (move + delete) | `scripts/spike03-image-headroom.sh` | **exact** — same two-subcommand shape, same "the file IS the gate" |
| `scripts/phase05-now-tag-inventory.sh` (new; regenerate `/tmp/now_tags.tsv` durably) | read-only inventory / capture | file-I/O, batch, resumable | `scripts/snapshot-music-tags.sh` | **exact** — per-file ffprobe, ledger resume, output under `/mnt/fast` |
| `scripts/phase05-now-split.sh` (new; D-02/D-05/D-07/D-08/D-09) | mutating filesystem tool, dry-run-first | batch rename(2) within one dataset | `scripts/spike03-image-headroom.sh` (gate) + `normalise-dj-tags.py` (dry-run default) | **role-match** (composite) |
| `scripts/normalise-dj-tags.py` — **add rule 4, canonical `album`** (D-10) | tag writer | transform, in-place metadata write | itself — rules 1/2 at `:296-390`, dispatch at `:1167-1181` | **exact** (extend, do not fork) |
| Snapshot + `chown` step (D-01, D-24) — likely `scripts/phase05-downloads-chown.sh` or a subcommand | privileged delegation to atlantis | ssh → `zfs snapshot` / `chown -R` / `zfs diff` | `scripts/freeze-music-apply.sh` `do_fence` + `do_ownership` (`:126-151`, `:536-598`) | **exact** — this IS Phase 1's 01-08 method |
| D-21 inode proof (fixture + cross-dataset negative control) | driven assertion with negative control | request-response, synthetic fixture | `spike03-image-headroom.sh` refusal-is-reachable pattern; `quick-health-check.sh` `VENDORED_DRIFT` negative control (`:463-487`) | **role-match** |
| `scripts/quick-health-check.sh` — D-22 criterion-4 assertion fold-in | standing check | remote read over ssh, assert | itself — `:826-871` (the canonical bounded-remote-count block) | **exact** |
| `stacks/selfhosted/arrs/beets.md` — Phase 5 closure section | durable estate record | documentation | same file, `:1126-1165` (Phase 4 closure) and `:974` (Phase 3) | **exact** |
| `.planning/ROADMAP.md` + `.planning/REQUIREMENTS.md` — D-12 in-band dated amendment (with D-14 folded in) | in-band amendment | documentation | `ROADMAP.md:262-272` (02.1-11) and `:526-549` (04-04 D-20); `REQUIREMENTS.md:276` (TAGR-05 addendum) | **exact** |

---

## Pattern Assignments

### 1. `scripts/phase05-junk-sweep.sh` — the D-13 approval gate

**Analog:** `scripts/spike03-image-headroom.sh` — **the single most important analog in this phase.**
D-13 says this shape *is* the review. 02.1-09 ran it for real (4 rows approved, 1.45 GiB reclaimed).

**The structural rule, verbatim from the analog's header (lines 37-50):**

```bash
# THE KEY (OD-1) - WHY THIS IS TWO SUBCOMMANDS AND NOT ONE SCRIPT WITH A PROMPT:
#   Reclaiming that space is a delete on a live shared host. The approval therefore has to sit
#   between two PROCESSES joined by a file on disk, not between two branches of one process: a
#   branch can be skipped by a flag, an env var or a future edit, a missing file cannot. `inventory`
#   writes $REAP_LIST and stops. `prune` reads $REAP_LIST or refuses. That is the whole design.
```

For Phase 5 the two subcommands become `enumerate` (read-only) and `sweep` (moves to
`99-quarantine`, then deletes what survived in the file). **D-13 says the gate blocks BOTH the move
and the delete**, so a *single* approved file gates both — not two separate approvals.

**Constants and flag block to copy (lines 100-104, 141-155):**

```bash
set -euo pipefail

FLOOR_GB="${FLOOR_GB:-8}"
OUT_DIR="${OUT_DIR:-/mnt/fast/spike-03/out}"
REAP_LIST="${REAP_LIST:-$OUT_DIR/reap-list.txt}"
...
usage() {
  echo "usage: bash scripts/spike03-image-headroom.sh {inventory|prune}" >&2
  echo "       bash scripts/spike03-image-headroom.sh --help" >&2
  exit 2
}

ACTION="${1:-}"
case "$ACTION" in
  -h|--help)
    # Self-documenting help (check-music-freeze.sh:96-99): the header block IS the help text, so
    # the two can never drift apart.
    grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac
```

**Refusal, not fallback — the first statement of the acting subcommand (lines 367-378):**

```bash
do_prune() {
  # Refusal, not a fallback. Checked FIRST, before docker is even required, so the refusal is
  # reachable and testable anywhere - including on a workstation with no docker at all.
  if [ ! -f "$REAP_LIST" ]; then
    echo "❌ reap list not found: $REAP_LIST" >&2
    echo "   Run 'bash scripts/spike03-image-headroom.sh inventory' first, then have the list" >&2
    echo "   approved by the operator. Refusing to guess what may be deleted." >&2
    exit 2
  fi
```

**RE-VALIDATE THE APPROVED LIST AGAINST FRESH STATE BEFORE ACTING (lines 397-420).** This matters
more here than in the analog, because `05-PREMEASURE.md` § Limits says the download tree is written
at ~1 job / 72 s — a `_UNPACK_` path can become a live job between approval and sweep:

```bash
  # A container may have been created between approval and now. The list is re-validated against a
  # FRESHLY derived referenced set immediately before anything is deleted - the approval says which
  # images the operator is willing to lose, not that they are still unreferenced.
  local refs; refs="$(referenced_set)"
  local conflicts=0 listed=0
  while IFS=$'\t' read -r name id size; do
    [ -z "${name:-}" ] && continue
    listed=$((listed + 1))
    if printf '%s\n' "$refs" | grep -qxF "$name" || printf '%s\n' "$refs" | grep -qxF "$id"; then
      fail "$name ($id) is NOW referenced by a container - it was not when the list was made"
      conflicts=$((conflicts + 1))
    fi
  done < "$REAP_LIST"

  if [ "$conflicts" -gt 0 ]; then
    fail "aborting: ${conflicts} listed image(s) became referenced after approval. Nothing deleted."
    exit 1
  fi
```
**Phase 5 translation:** re-derive the candidate set from the live tree; if an approved path no
longer matches its rule, or has gained content, or now sits under `incomplete/` (D-15 out of scope),
**abort the whole sweep** rather than skip the row.

**Act one item at a time, by name from the file, collecting rather than aborting (lines 426-459):**

```bash
  while IFS=$'\t' read -r name id size; do
    [ -z "${name:-}" ] && continue
    if ! docker image inspect "$id" >/dev/null 2>&1; then
      info "already reclaimed: $name ($id)"
      already=$((already + 1))
      continue
    fi
    ...
    if docker rmi "$target" >/dev/null 2>&1; then
      pass "removed $name ($id, $size)"
      removed=$((removed + 1))
    else
      # Collect rather than abort: one image held by something unexpected must not strand the rest.
      fail "docker rmi failed for $name ($id) - left in place"
      errors=$((errors + 1))
    fi
  done < "$REAP_LIST"
```

**Prohibited-primitive rule to mirror (lines 48-50).** The analog bans `docker image prune -a` /
`docker system prune` because they "decide for themselves what is unreferenced ... with no list a
human ever saw". **The Phase 5 equivalent to ban: `find … -delete`, `rm -rf` over a glob, and any
`xargs rm` whose input is not `$APPROVED_LIST`.** State the ban in the header and make it a
comment-stripped grep at acceptance — the analog's own acceptance was
`grep -v '^\s*#' … | grep -c 'docker image prune'` returning 0, and lines 382-385 record that an
*echoed banner string* satisfies that grep as well as real code does, so keep the banned word out of
prose too.

**Explicit "nothing has been deleted" close on the read-only half (lines 357-362):**

```bash
  warn "NOTHING HAS BEEN DELETED. An operator must approve $REAP_LIST before 'prune' will act."
  ...
  # inventory reports, it does not assert.
  return 0
```

**Exit-code convention, stated not inherited (lines 81-88)** — copy this block's *shape* verbatim,
substituting Phase 5's conditions:

```
# EXIT-CODE CONVENTION (stated here deliberately, not inherited - the estate has no single one;
# see check-music-freeze.sh:31-38 for why that silence is itself a hazard):
#   inventory  0 always. It REPORTS; it does not assert.
#   prune      0  every approved image is gone AND avail >= FLOOR_GB
#              1  pruned but still below the floor, or at least one `docker rmi` failed, or a
#                 listed image became referenced between approval and prune
#              2  usage error, or $REAP_LIST does not exist (refusal, never a fallback)
```

**⚠ ZFS async free (D-11 + `CLAUDE.md`).** The analog re-reads `df` immediately after deleting and
asserts a floor. On `tank`, `zfs list` lags a large delete by ~20 s — so do **not** copy the
"measure space immediately after" assertion unchanged. Assert *absence of the deleted paths*, and
report reclaimed space as informational with the lag named.

---

### 2. `scripts/phase05-now-tag-inventory.sh` — regenerating the `Now!` scan durably

**Analog:** `scripts/snapshot-music-tags.sh`. `05-CONTEXT.md` § Canonical References says the scan
behind D-03/D-04/D-08/D-10 lived at `/tmp/now_tags.tsv` on LXC 100 and **is gone** — tmpfs.

**Where-it-runs header block to copy (lines 1-9, 68-72):**

```bash
#!/usr/bin/env bash
# snapshot-music-tags.sh - Capture the pre-project tag before-state ...
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull`.
#   Host-resident rather than workstation-resident because this reads ~140 GB off `tank` and
#   spawns two processes per file; it cannot be expressed as one ssh'd command. Same convention
#   as scripts/setup-mpe.sh, scripts/pg-migrate.sh and scripts/freeze-music-apply.sh.
...
# NOTHING is written to the system temp directory. On LXC 100 that directory is tmpfs backed by
# host RAM; a 1.1 GB file staged there previously took the whole 28 GB box down and killed ssh on
# both the host and the container. Every byte this script writes lands under /mnt/fast.
```

**Output location constants (lines 76-77)** — `/mnt/fast/safety` is Phase 1's fence and
`05-CONTEXT.md` names it as the durable home for this inventory:

```bash
FENCE="/mnt/fast/safety/music-pre-project"
OUTDIR="${FENCE}/tags"
```

**ffprobe invocation — ONE INPUT FILE, stdin closed (lines 289-311).** `05-CONTEXT.md` records that
`xargs -n 50 ffprobe` silently produced nothing and exited clean during the discussion. The analog's
shape is the fix:

```bash
      raw="$(ffmpeg -nostdin -v error -i "$f" -map 0:a -c copy -f md5 - 2>/dev/null)" || rc=$?
      ...
      line="$(ffprobe -v quiet -print_format json -show_format -show_streams -- "$f" </dev/null \
```
Note **three** load-bearing details: `-nostdin` on ffmpeg and `</dev/null` on ffprobe (so neither
swallows the loop's stdin), and `--` before the path.

**Build the record with `jq`, never by string concatenation (lines 193-208):**

```bash
# emit_record AUDIO_MD5 PATH ROOT SIZE MTIME  <  ffprobe JSON on stdin
# jq builds the whole line; the ffprobe output arrives as `.` and is embedded verbatim.
emit_record() {
  jq -c \
    --arg audio_md5   "$1" \
    --arg source_path "$2" \
    ...
      ffprobe:     .}'
}
```
The `Now!` inventory needs `album`, `disc`, `track`, `tracktotal` and path per file. **Emit NDJSON
via `jq` rather than a TSV built with `printf`** — album values in this collection contain commas,
exclamation marks and a **double space** (D-03), and a TSV of them is one stray tab from silent
misalignment. If a TSV is still wanted for eyeballing, generate it *from* the NDJSON.

**Resume ledger (lines 53-63, 220-241)** — the `Now!` scan is 4,746 files on a live tree:

```bash
# RESUMABILITY (D-02): the ledger, not a re-scan of the NDJSON. `<BASENAME>.done` is loaded once
#   into an associative array on start and any path already present is skipped.
#   Ordering within a file is: emit the NDJSON line, THEN append to `.done`. A hard kill in that
#   window re-emits one record on the next run; it never loses one.
#   A file whose ffmpeg or ffprobe exits non-zero goes to `.failed` and is NOT written to `.done`,
#   so a re-run retries it rather than permanently skipping it.
```

**A raise is never a no-op.** The analog keeps `.failed` as a separate ledger; `normalise-dj-tags.py`
states the reason (`:69-71`): *"A raising file is NEVER counted as 'no change': conflating an
exception with a no-op result is precisely how Phase 1 produced six unearned passes."*

---

### 3. `scripts/phase05-now-split.sh` — the per-volume split (D-02/D-05/D-07/D-08/D-09)

No single analog. Compose two:

**(a) Dry-run-by-default, from `normalise-dj-tags.py`'s stated flag convention (`:144-151`):**

```
  FLAG CONVENTION (deliberately inverted from scripts/check-music-freeze.sh)
    `check-music-freeze.sh:31-38` makes the destructive-sounding mode the flag and the audit the
    default. Here it is the other way round: `--dry-run` IS THE DEFAULT and writing requires an
    explicit `--apply`. An irreversible in-place tag write over reflinked copies earns a stricter
    default than a read-only audit does, and inverting this is the single cheapest safety control
    available. The inversion is stated out loud because silently inheriting a convention is how
    the docker `created`-state blind spot hid two down containers for six weeks under a green
    check.
```
4,746 `rename(2)` calls with no undo earn the same default. Note that D-13's *approval-file* gate is
a stronger control than a `--dry-run` default; if the split's destination mapping is derived
(m3u + album cross-check), consider emitting the full `src<TAB>dst` mapping as an approvable file
and having `--apply` act from it — that turns two independent instruments (D-02) into one reviewable
artifact and matches the operator's Phase 3 verdict (*"read and approve a file; never sit at a
prompt"*).

**(b) The snapshot-proof refusal, from `normalise-dj-tags.py:955-1001`** — this is the exact
mechanism D-01 needs, and it already solves "zfs cannot run where the tool runs":

```python
def check_snapshot_proof_or_die(proof_path: str | None) -> str:
    """`--apply` refuses unless the rollback snapshot is proven to exist. Never a skip."""
    if not proof_path:
        sys.stderr.write(colour(
            "REFUSING TO APPLY: --snapshot-proof is required.\n"
            f"  {SNAPSHOT_NAME} is this script's ONLY rollback, and `zfs` cannot resolve on\n"
            "  LXC 100 or inside this container, so the check is delegated. Produce the proof\n"
            "  on atlantis and pass it:\n"
            "    ssh -o BatchMode=yes -o ConnectTimeout=5 root@172.16.1.158 \\\n"
            f"      'zfs list -t snapshot -H -o name {SNAPSHOT_NAME}' > <proof file>\n"
            "  An unreachable atlantis means the snapshot state is UNKNOWN, which is a refusal,\n"
            "  not a skip and not a pass.\n", RED))
        sys.exit(2)
    if not os.path.isfile(proof_path): ... sys.exit(2)
    ...
    if SNAPSHOT_NAME not in body: ... sys.exit(2)
```
**Change `SNAPSHOT_NAME` to `tank/downloads@pre-phase5` for every Phase 5 mutating tool.** D-01 makes
the snapshot the first act; this is the enforcement that makes "first act" mechanical rather than
procedural. `05-PREMEASURE.md` § 2 confirms `@pre-project` / `@pre-chown` are a month stale, so
**a proof file naming the wrong snapshot must fail** — the substring check above does exactly that.

**(c) The scope fence, from `normalise-dj-tags.py:932-952`** — refuse loudly, naming both paths:

```python
def resolve_target_or_die(target: str) -> str:
    """The scratch-root fence (T-03-23). Refuses loudly, naming both paths, and exits 2."""
    root = os.path.realpath(SCRATCH_ROOT)
    real = os.path.realpath(target)
    if real != root and not real.startswith(root + os.sep):
        sys.stderr.write(colour(
            "REFUSING TO RUN: target is outside the spike scratch root.\n"
            f"  given:    {target}\n"
            f"  resolved: {real}\n"
            f"  required: {root} (or a descendant)\n", RED))
        sys.exit(2)
```
Phase 5's fence root is `/mnt/tank/downloads`; **`/mnt/tank/media/Music` must be refused by name**
(Phase 1 D-20 — nobody holds `rw` there until Phase 6).

**(d) Reconciliation asserted, not hoped for — `normalise-dj-tags.py:1284-1289`:**

```python
    # WR-06: THE RECONCILIATION, ASSERTED RATHER THAN HOPED FOR.
    # The four buckets are meant to be DISJOINT and to account for every file counted into
    # files_seen. Every path takes exactly one route ... Stating that as an equation and
```
D-08 asks for exactly this: assert `Σ per-volume mp3 counts == 4,746` **and** the stronger per-volume
identity `files == Σ tracktotal`, with the 24 manifest-only entries on their **own line**, never
folded into the total. The buckets must be disjoint — the analog's WR-06 comment (`:1154-1164`)
records a live defect where one file landed in two buckets and `files_seen` never balanced.

---

### 4. `scripts/normalise-dj-tags.py` — adding the canonical-`album` rule (D-10)

**Analog: itself.** D-10 is explicit: *"Do not write a second tool."* The file is already
dry-run-by-default, fenced, and has a field-loss backstop. Four slots to fill.

**Slot 1 — the writable-field constants (`:237-240`).** `album` is **already** writable, so no
widening is needed:

```python
WRITABLE_FIELDS = ("album", "artist")
FIELD_FRAME = {"album": "TALB", "artist": "TPE1"}
```
**Do not add a field.** D-10 is one field on one collection.

**Slot 2 — a rule as a pure, idempotent function, sectioned like rules 1 and 2 (`:365-390`):**

```python
# --------------------------------------------------------------------------------------------
# Rule 2 - canonicalise a present-but-noisy album. V5.
# --------------------------------------------------------------------------------------------


def canonicalise_album(value: str) -> str:
    """Fixed point on its own output, which is what makes a second --apply a no-op.

    Target form is the SAME form rule 1 produces - `<Label> <Series> <NNN>` - because a
    canonicalisation that lands somewhere else than the derivation would leave the two halves of
    the sample carrying two different album shapes into the same Discogs query.
    """
    a = value.replace("_", " ")
    a = unicodedata.normalize("NFC", a)
    a = CONTROL_RE.sub("", a)
    a = WHITESPACE_RE.sub(" ", a).strip()
    ...
    return WHITESPACE_RE.sub(" ", a).strip()
```
The new rule is **not** a value-transform of the existing tag. **D-03 forbids parsing a volume number
out of the `album` string** (`…Vol.36 CD1` → `1`, `…Vol.36  CD2` → `2`, double space included;
volume 1 has no number, volume 2 is a Roman numeral with a comma). The canonical string must come
from **the folder the split produced** — i.e. the same *class* as rule 1
(`derive_album_from_folder`, `:326-362`), not rule 2. D-10 says run it "after the split, per volume
folder", and the per-folder loop already exists (`collect_folders()` at `:1040`, and rule 3's
per-folder consensus at `:1183-1214` is the working precedent for a folder-scoped decision).

**Slot 3 — the sanitiser, if any part of the string is path-derived (`:302-323`):**

```python
def sanitise_derived(value: str) -> str | None:
    """Sanitise path-derived data before it becomes file metadata (T-03-26, ASVS V5)."""
    v = unicodedata.normalize("NFC", value)
    v = SEPARATOR_RE.sub(" ", v)
    v = CONTROL_RE.sub("", v)
    v = WHITESPACE_RE.sub(" ", v).strip()
    v = v[:MAX_ALBUM_LEN]
    # Re-validate rather than trust the transform above.
    if not v: return None
    if SEPARATOR_RE.search(v) or CONTROL_RE.search(v): return None
    if len(v) > MAX_ALBUM_LEN: return None
    if not re.search(r"\d", v):
        # A derived album with no issue number identifies no release ...
        return None
    return v
```
⚠ **The `if not re.search(r"\d", v)` guard rejects volume 1 if the canonical form is
`Now That's What I Call Music!` with no number.** `05-CONTEXT.md` § Claude's Discretion leaves the
canonical format open (*"e.g. whether volume 1 becomes `Now That's What I Call Music! 1`"*) — pick a
form that carries the number on **all 115**, which both satisfies this guard and makes the string a
usable Discogs query.

**Slot 4 — the dispatch site (`:1167-1181`), where the new rule slots in:**

```python
        # ---- rules 1 and 2, per file -----------------------------------------------------
        proposals: dict[str, dict[str, tuple[int, str | None, str]]] = {}
        for path, _handle, values in loaded:
            album = values["album"]
            if album is None or not album.strip():
                derived, reason = derive_album_from_folder(folder_name)
                if derived is None:
                    skipped_paths.add(path)  # WR-06: state, not a counter - see above
                    log.warning("rule 1 skipped %s: %s", path, reason)
                    continue
                proposals.setdefault(path, {})["album"] = (1, album, derived)
            else:
                canonical = canonicalise_album(album)
                if canonical and canonical != album:
                    proposals.setdefault(path, {})["album"] = (2, album, canonical)
```
A proposal is a `(rule_number, old, new)` tuple keyed by field. Add rule `4`; it must be **mutually
exclusive** with rules 1 and 2 on `album` (a `dict` key collision would silently let the last writer
win). The cleanest shape is a mode/target gate: when the target is the `Now!` tree, rule 4 owns
`album` outright and rules 1/2 do not run. Also add `rule_hits[4]` to the summary (`:1325-1327`).

**THE FIELD-LOSS GATE — copy nothing, just know it already fires (`:734-772`):**

```python
def assert_frame_set_unchanged(path, before, changes: dict[str, str], *, offset: int = 0) -> None:
    """After the write, the on-disk ID3v2 frame-ID multiset must be what it was, plus the two.
    ...
    "Assert rather than report" - README § Health Checks. Frame ENCODINGS and SIZES are allowed to
    move (mutagen terminates latin-1 text frames with a NUL, which is legal and harmless); frame
    IDENTITY is not.
    """
    if before is None: return
    after = id3v2_frame_ids(path, offset)
    if after is None:
        raise RuntimeError("ID3v2 tag became unreadable during save")
    written = {FIELD_FRAME[f].encode("ascii") for f in changes}
    ...
    if a != b:
        raise RuntimeError(f"ID3v2 frame set changed beyond {sorted(...)}: ...")
```
This runs inside `write_tags()` and is what makes the D-10 write auditable per file. The
**collection-level** proof is the QUAL-01 pair (§ 5 below).

**The three mutagen defaults that broaden a write (`:82-94`)** — they are already handled; do not
"simplify" them away when adding rule 4:

```
  * MUTAGEN DOES NOT WRITE BACK WHAT IT READ. It re-serialises its own normalised in-memory
    model, and THREE of its defaults quietly broaden the write past `album` and `artist`:
      - `ID3(path, v2_version=3)` at LOAD time, or TYER/TDAT/TIME are translated to TDRC ...
      - `ID3(path, load_v1=False)`, or mutagen synthesises a `COMM:ID3v1 Comment:eng` frame ...
      - the trailing ID3v1 block is restored BYTE-FOR-BYTE after every save, because
        `save(v1=UPDATE)` regenerates all 128 bytes from the ID3v2 frames — which also MOVES
        `audio_md5`, the key `snapshot-music-tags.sh` and `diff-music-tags.sh` join on.
```
⚠ **That third bullet is the one D-10 rests on.** `05-CONTEXT.md` says the tag write is safe because
QUAL-01's key is `audio_md5`. That is true **only because `preserve_id3v1_trailer()` exists** — an
ID3v1 regeneration moves the key. The `Now!` collection is 4,746 **mp3**, the exact format this trap
was measured on. State the dependency in the plan; do not restate the safety claim without it.

**WHERE IT RUNS — the reason this tool is different from every other script (`:10-36`):**

```
WHERE IT RUNS
  INSIDE the `beets-spike` container on LXC 100 (root@172.16.1.159), not on the host:
  ... the host has python3 3.13.5 but NO `pip3`, NO `python3-venv`, `import ensurepip` raises
  ModuleNotFoundError ... and /usr/lib/python3.13/EXTERNALLY-MANAGED is present ...
  `import mutagen` is therefore impossible on the host
```
⚠ **Plan consequence:** the D-10 step needs a **container with mutagen**, and the dry-run/apply split
in the analog runs the read on `beets-spike` (`:ro`) and the write on `beets-spike-rw`. Phase 4
retired the spike stack — **the planner must confirm which container/image provides mutagen at
Phase 5 execution time, and whether a `--rw` arm still exists**, or plan a
`docker run --rm --pull never --network none --entrypoint python3 -v …:ro lscr.io/linuxserver/beets:2.13.1…`
invocation (the `--self-test` recipe at `:163-165` is the working template). Also note the fence at
`:173-187`: `SCRATCH_ROOT = "/mnt/tank/downloads/spike-03"` — **the Phase 5 target is not under it**,
so `resolve_target_or_die()` will refuse the `Now!` tree as written. Widening that fence is a
deliberate, reviewable edit; it is the single riskiest line-change in this phase.

---

### 5. Proving D-10 lost nothing — the QUAL-01 instrument

**Analogs:** `scripts/snapshot-music-tags.sh` (capture) → `scripts/diff-music-tags.sh` (gate).
The exact invocation sequence is already written down at `normalise-dj-tags.py:53-61`:

```
WORKFLOW
  ssh root@172.16.1.158 'zfs list -t snapshot -H -o name tank/downloads@spike-03-t0' \
      > /mnt/fast/spike-03/out/snapshot-proof.txt          # UNKNOWN if this fails - do not proceed
  docker exec beets-spike    python3 ... <TARGET> --out .../normalise-dryrun.ndjson   # review
  docker compose -f ... --profile manual up -d beets-spike-rw
  docker exec beets-spike-rw python3 ... <TARGET> --apply --snapshot-proof ... --out .../apply.ndjson
  docker compose -f ... --profile manual down beets-spike-rw     # take the writer arm down at once
  bash scripts/snapshot-music-tags.sh spike03-after --roots <TARGET>
  bash scripts/diff-music-tags.sh <before>.ndjson.gz <after>.ndjson.gz     # the field-loss gate
```
Substitute `tank/downloads@pre-phase5` and the `Now!` target. Note `--roots` and `--limit`
(`:12-18`) let the after-capture be scoped to one tree rather than re-reading 140 GB.

**The gate's contract (`diff-music-tags.sh:15-32`):**

```
# Categories reported:
#   1. MATCHED         audio_md5 present on both sides
#   2. MISSING_AFTER   in BEFORE, absent from AFTER - the file-level loss case
#   3. NEW_AFTER       in AFTER, absent from BEFORE
#   4. FIELDS_DROPPED  per matched file, tag keys in BEFORE and absent in AFTER - the QUAL-02 gate
#   5. FIELDS_GAINED / 6. FIELDS_CHANGED
#
# EXIT CODES (the contract Phase 7 gates on):
#   0  no net metadata loss - MISSING_AFTER is 0 AND FIELDS_DROPPED is 0
#   1  loss detected        - either is non-zero
#   2  usage or input error
```
**Expected Phase 5 result:** `FIELDS_CHANGED` non-zero on `album` (that is the intended write),
`FIELDS_DROPPED` and `MISSING_AFTER` **zero**. Pre-declare that in the plan (D-04 / Phase 4 D-31
pattern) so a verifier meets a known shape.

**The vacuous-pass guard (`:43-46`) — quote it in the plan:**

```
# A near-empty tag set is a legitimate BEFORE state, not a capture failure ... The summary
# therefore reports how many matched files had ZERO tag fields on the BEFORE side, so "no fields
# dropped" cannot be read as a pass when it is really "there was nothing there to drop".
```

---

### 6. Snapshot, `chown` and `zfs diff` — D-01 / D-23 / D-24

**Analog:** `scripts/freeze-music-apply.sh` — this file **is** Phase 1 plan 01-08's method.

**Constants (`:67-79`) — every Phase 5 execution constraint is already encoded here:**

```bash
set -euo pipefail

LIBRARY="/mnt/tank/media/Music"
DOWNLOADS="/mnt/tank/downloads"
DJMIXES="/mnt/tank/downloads/complete/nzb/dj-mixes"
APPDATA="/mnt/fast/appdata"
FENCE="/mnt/fast/safety/music-pre-project"
SNAPTAG="pre-project"
UIDGID="568:568"
DIR_MODE="755"
FILE_MODE="644"
ZFS_HOST="172.16.1.158"                       # Proxmox host "atlantis" - the only place zfs exists
RSYNC_FLAGS="-rlt --no-p --no-o --no-g"       # never -a on tank; see RSYNC NOTE above
```
`UIDGID="568:568"` is D-23/D-24's value; `ZFS_HOST` is the delegation target; `RSYNC_FLAGS` is the
`rsync -a`-fails-on-tank workaround **already solved** (though D-07's split is `rename(2)`, so no
copy should be needed at all).

**Route detection + delegation (`:126-151`) — copy this wholesale:**

```bash
# ─── zfs routing ──────────────────────────────────────────────────────────────
# Read-only detection first, so the route is known and printed before anything mutates.
ZFS_ROUTE="unavailable"
detect_zfs_route() {
  if command -v zfs >/dev/null 2>&1; then
    ZFS_ROUTE="local"
  elif ssh -o BatchMode=yes -o ConnectTimeout=8 "root@${ZFS_HOST}" 'zfs list -H -o name tank' >/dev/null 2>&1; then
    ZFS_ROUTE="ssh:${ZFS_HOST}"
  else
    ZFS_ROUTE="unavailable"
  fi
}

# zfs_exec "<full zfs command line>" - runs locally or on the Proxmox host, per the detected route.
zfs_exec() {
  local cmdline="$1"
  if [[ "$ZFS_ROUTE" == "local" ]]; then
    eval "$cmdline"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=15 "root@${ZFS_HOST}" "$cmdline"
  fi
}

snapshot_exists() { zfs_exec "zfs list -t snapshot -H -o name '$1'" >/dev/null 2>&1; }
snapshot_creation() { zfs_exec "zfs get -H -p -o value creation '$1'" 2>/dev/null || echo "unknown"; }
```

**The D-01 snapshot call (`:233`, `:240`):**

```bash
      zfs_exec "zfs snapshot tank/media/Music@${SNAPTAG}"
      ...
      zfs_exec "zfs snapshot tank/downloads@${SNAPTAG}"
```
Phase 5: `zfs_exec "zfs snapshot tank/downloads@pre-phase5"`.

**The guarded, scope-fenced, delegated chown (`:536-598`) — the D-24 analog in full:**

```bash
do_ownership() {
  banner "ownership - normalising $LIBRARY to ${UIDGID} (mode pass scoped out, D-12)"

  # Precondition guard (pg-migrate.sh guard-then-SKIP shape). The snapshot is the only rollback
  # for a bad recursive chown across 2,673 entries. Without it this must not execute.
  detect_zfs_route
  echo "    zfs route: $ZFS_ROUTE"
  if [[ "$ZFS_ROUTE" == "unavailable" ]]; then
    err "SKIP: no zfs route - cannot confirm tank/media/Music@${SNAPTAG} exists, and that snapshot is this subcommand's only rollback"
    return 1
  fi
  if ! snapshot_exists "tank/media/Music@${SNAPTAG}"; then
    err "SKIP: tank/media/Music@${SNAPTAG} does not exist. Run \`$0 fence\` first ..."
    return 1
  fi
  ok "precondition met: tank/media/Music@${SNAPTAG} exists"
  ...
  # SCOPE GUARD (T-01-46). The chown below runs as REAL root on the Proxmox host, not as a
  # namespaced container root, so a wrong LIBRARY constant here is a hypervisor-wide recursive
  # chown rather than a contained mistake. Assert the literal before delegating anything.
  if [[ "$LIBRARY" != "/mnt/tank/media/Music" ]]; then
    err "SKIP: LIBRARY is '$LIBRARY', expected '/mnt/tank/media/Music'. Refusing to run a recursive chown as real root against an unexpected path."
    return 1
  fi

  read -r b_own b_dm b_fm b_tot <<< "$(census_counts)"       # the BEFORE census
  ...
  echo "==> Setting ownership ${UIDGID} (route: ${ZFS_ROUTE})..."
  if [[ "$ZFS_ROUTE" == "local" ]]; then
    chown -R "${UIDGID}" "${LIBRARY}"
  else
    # Re-assert the path on the far side: a bind mount present here but absent there would
    # otherwise make `chown -R` a silent no-op against a path the remote auto-creates.
    ssh -o BatchMode=yes -o ConnectTimeout=15 "root@${ZFS_HOST}" \
      "test -d '${LIBRARY}' && chown -R '${UIDGID}' '${LIBRARY}'" \
      || { err "remote chown failed or ${LIBRARY} is absent on root@${ZFS_HOST}"; return 1; }
  fi
  ok "chown complete"
```
**Four things to carry over verbatim in shape:** the **snapshot precondition** (D-01 is Phase 5's),
the **ALL-CAPS literal scope guard** (Phase 5's constant is `/mnt/tank/downloads` — and the blast
radius is the hypervisor, same as Phase 1), the **remote `test -d` re-assertion**, and the
**before census** so `zfs diff` has something to be compared against.

**The chown/chmod mechanism comments (`:574-609`)** — reproduce the substance, do not re-derive it:

```
  # Cause: LXC 100 is unprivileged with a sparse idmap. ... A process in a user namespace cannot
  # chown a file whose current uid or gid is unmapped - CAP_CHOWN in a nested namespace does not
  # reach ids the namespace cannot name. This is NOT the aclmode=restricted problem; it is a
  # different mechanism with the same errno, which is exactly why it was mistaken for one.
  ...
  # ── the mode pass is DELIBERATELY NOT RUN (D-12 scoped out, user decision 2026-08-18) ───────
  # Not skipped by accident, not swallowed with `|| true`, and not retried. `chmod` is IMPOSSIBLE
  # on this pool: it returns EPERM as real root for every mode, including a no-op `chmod 0777` on
  # a file already at 0777.
```
Phase 5's `05-CONTEXT.md` § Ownership restates both; the analog is where the wording came from.

**The verification instrument — `zfs diff`, and why `stat` is not it.** From `01-08-PLAN.md:20-21`:

> *"A FRESH SNAPSHOT `tank/media/Music@pre-chown` is taken immediately before the sweep, as this
> plan's own baseline (finding from 01-06). The chown moves ctime on ~2,543 entries, so a later
> `zfs diff` against `@pre-project` would drown the real signal in 2,543 expected M lines"*
>
> *"`zfs diff` against that fresh snapshot is the ONLY instrument that can verify this plan. The
> stat manifest keys on mtime (%T@) and chown moves ctime, not mtime — 01-06 proved this when its
> gate 4 passed while `zfs diff` showed a real metadata change. A zero from the stat manifest
> afterwards is EXPECTED, not reassuring"*

And the executed result, `01-08-SUMMARY.md:247-279`:

```
### Verification — `zfs diff`, the only instrument that can see this
zfs diff tank/media/Music@pre-chown tank/media/Music
...
| `zfs diff tank/downloads@pre-chown tank/downloads` | **0 lines** |
```
⚠ **D-01 and D-24 want the SAME snapshot to serve two purposes on the same dataset.** Phase 1 needed
`@pre-chown` *separate from* `@pre-project` precisely because a chown-moved ctime drowns the signal.
D-27 orders chown **last**, so `@pre-phase5` will already carry the split's 4,746 renames when the
chown runs, and a `zfs diff` against it will show them all. **Take a second snapshot immediately
before the chown** (e.g. `tank/downloads@pre-phase5-chown`) so the chown has its own clean baseline —
this is the direct, dated lesson from 01-06/01-08 and the planner should not have to rediscover it.
Also note Phase 1 used `tank/downloads@pre-chown` as an **untouched-proof instrument**
(`01-08-SUMMARY.md:16`, expected 0 lines) — in Phase 5 that role is gone, since `tank/downloads` is
the target. Pick a different untouched dataset for the negative half, or drop the claim.

**Scale warning, unanalogised.** Phase 1 was 2,674 entries and `zfs diff` returned 2,674 `M` lines.
D-24 is **209,039 entries (~74×)**, of which 197,776 are uid 3000. Expect a `zfs diff` output of
~200k lines — **assert on counts and on the absence of `+`/`-`/`R` lines, never print it raw**, and
give the step its own timing expectation as D-24 requires.

---

### 7. D-21's inode proof and its cross-dataset negative control

**Analog (doctrine):** `quick-health-check.sh:463-487` — the `VENDORED_DRIFT_PROMOTED` block, the
estate's clearest written example of *"prove the instrument can fail"*:

```bash
# THE HISTORY IS KEPT, because the reason for the gate is the reason the promotion is safe.
...
# precisely the permanent red the notice at the top of this file promises this script does not
# inherit, and a permanently-red check trains the reader to ignore it. The first run being red on
# REAL state was valuable and was kept: it is this block's driven negative control (04-10 named
# both undelivered files with both hashes). It was simply run deliberately, under the opt-in,
# rather than at everyone who typed the script. It is green now because the host was given the
# files, not because the comparison was loosened.
VENDORED_DRIFT_PROMOTED=1
```

**Analog (measurement):** `05-PREMEASURE.md` § 1 already supplies both sides of the instrument —
`tank/downloads` is `devid=68`, `tank/media/Music` is `devid=76`, and § 3 records real inodes
(`243398` for the `dj-mixes` decoy, `15900` for the real folder). The fixture test reads `stat`'s
inode before and after `mv`.

**Concrete shape:** positive control = `mv` between two `_inbox/` dirs, assert inode **unchanged**;
negative control = `mv` the same fixture across a `devid` boundary, assert inode **changed**.
⚠ D-21's own constraint: the obvious negative target is `/mnt/tank/media/Music`, barred by Phase 1
D-20. **The property under test is "a different `devid` changes the inode", not "Music specifically"** —
`/mnt/fast/...` (a different pool entirely) or a host-side dataset both satisfy it, and running from
atlantis with self-cleanup is the other sanctioned route. Planner's choice per `05-CONTEXT.md`.

---

### 8. `scripts/quick-health-check.sh` — the D-22 criterion-4 fold-in

**Analog: itself.** The criterion-4 assertion is "zero `_`-prefixed directories under
`/mnt/tank/media/Music`" — a remote `find … | wc -l`, which is **exactly** the shape the file's
longest comment is about.

**The canonical block to copy (`:796-839`):**

```bash
# Corrected 2026-09-03 by plan 02.1-15. Both count sites below carry the same two-part fix, and
# BOTH PARTS ARE NECESSARY ...
#   1. `set -o pipefail` IN THE REMOTE COMMAND STRING. `timeout T docker ps -q | wc -l` signals
#      only the FIRST stage. `wc -l` then reads the empty stream, prints `0` and exits 0, and
#      without pipefail the remote pipeline's status IS `wc`'s ... Driven on LXC 100:
#        timeout 2 sleep 20 | wc -l                    -> stdout 0, rc 0    (the bug)
#        set -o pipefail; timeout 2 sleep 20 | wc -l   -> stdout 0, rc 124  (the fix)
#   2. CAPTURE ssh's STATUS, AND BRANCH ON 124. pipefail alone is NOT enough, because `wc -l`
#      still PRINTS `0` on the killed path ... The value is unusable; only the status carries the
#      truth.
#
# THE STATUS MUST BE READ WITH NO LOCAL PIPE IN FRONT OF IT. `VAR=$(ssh ... | tr -d ' ')` makes
# `$?` the TR's status, and `${PIPESTATUS[0]}` DOES NOT RESCUE IT ...
RUNNING=$(ssh -n $SSH_OPTS root@172.16.1.159 "set -o pipefail; timeout $REMOTE_TIMEOUT docker ps -q | wc -l")
RUNNING_RC=$?   # ssh propagates the remote status — NO local pipe above, see the note above
RUNNING=$(printf '%s' "$RUNNING" | tr -d '[:space:]')
if [ "$RUNNING_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — 'docker ps' exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  Nothing was counted. This is NOT 'zero containers running'."
    EXIT_CODE=1
elif [ "$RUNNING_RC" -ne 0 ] || ! echo "$RUNNING" | grep -qE '^[0-9]+$'; then
    echo "⚠️  UNKNOWN — could not count running containers (ssh exit $RUNNING_RC, output '$RUNNING')."
    echo "  dockerd may be blocked. This is NOT 'zero containers running'."
    EXIT_CODE=1
else
    echo "Containers running: $RUNNING"
fi
```
**Three branches, never two** — `could not look`, `there are none`, `BROKEN` (`:822-825`). A
criterion-4 fold-in must read: UNKNOWN on rc 124 / non-numeric; `❌` on count > 0; `✅` only on a
genuine numeric zero. `05-PREMEASURE.md` § 6 says the true value today is **zero**, which makes the
green path the default — so the **negative control matters**: create a throwaway `_probe` dir,
confirm the check goes red, remove it. Otherwise this is an assertion never seen to fail.

**The greppable house rule (`:444-453`):**

```
#   4. AND THE BOUND DOES NOT BIND THROUGH A PIPE ON ITS OWN. ... Any remote command string in
#      this file that contains a `|` therefore needs BOTH `set -o pipefail` at the front of that
#      string AND the ssh status captured and branched on ... This is the greppable rule:
#      `grep -n 'timeout \$REMOTE_TIMEOUT.*|' ` over this file should return only lines whose
#      command string also contains `pipefail`, or lines whose final stage is a `grep -q` ...
```

**The bound and the host constants (`:417`, `:461`):**

```bash
SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=10"
REMOTE_TIMEOUT="${REMOTE_TIMEOUT:-120}"
```
⚠ Criterion 4's read targets `/mnt/tank/media/Music` on **atlantis** (`172.16.1.158`), not LXC 100 —
so the fold-in adds a second remote host to a file that currently ssh's almost everywhere to `.159`.
`:81` already names atlantis unreachability as a fatal "could not look", and `:942`/`:1209` show the
existing `if [ "$DASH_HOST" != "root@172.16.1.159" ]` host-override guard shape to reuse.

**⛔ D-25 FORBIDS the adjacent temptation.** Do **not** add a `tank/downloads` ownership assertion
here. `05-CONTEXT.md` D-25: it would go red on the next download (~1 job / 72 s) and train everyone
to ignore it — the exact failure mode 02.1's CR-01 spent four gap-closure plans repairing.

---

### 9. Markdown record updates

#### 9a. `stacks/selfhosted/arrs/beets.md` — the Phase 5 closure section

**Analog:** the same file's Phase 4 section, `:1126-1165`, and Phase 3's at `:974`. House conventions
visible there:

- **The heading carries the verdict, dated**: `## Phase 4 — closed 2026-09-18: criterion 3
  discharged by a signed override, not by a byte proof`, and `## Phase 3 — the tagger decision
  (2026-09-04)`.
- **An honest heading that contradicts itself is corrected in the first line, not rewritten**:
  `**Phase 4 is NOT closed, and this section is deliberately not headed as a closure.**`
- **Verdicts are QUOTED from the evidence artifact, with the artifact named**, not paraphrased:
  `Quoted from .planning/phases/…/04-D12-EVIDENCE.md, which carries exactly one verdict line per
  window`, followed by a `>` blockquote.
- **Superseded verdicts stay beside the current one**: *"Window 1's verdict stands beside it,
  unrevised in the light of anything window 2 produced. It is kept because it is the record of
  *why* the first attempt could not close the criterion."*
- **Distinctions are stated plainly**: `**Nothing failed.** OPEN is not FAIL: a FAIL needs a
  violated condition and there is none.`
- **Later developments are added in band and dated**: `**What has happened since, recorded in band
  and dated 2026-09-14.**`
- Existing sub-headings to model on: `### The five criteria`, `### What keeps these true`,
  `### Traps that will mislead the next person`, `### Recorded, not fixed`, `### Still open`,
  `### How to re-run`, `### Rollback — a TESTED two-sided teardown`.

**Phase 5 content these map onto:** `### The four criteria` (with D-22 recorded as *already green,
now asserted*), `### Traps that will mislead the next person` (D-03's `Vol.36 CD1` / `Vol.36  CD2`
double-space trap, verbatim per `05-CONTEXT.md` § Specific Ideas), `### Recorded, not fixed`
(volumes 4/8/9's tracktotal surplus; the 24 located missing tracks; the `LOCATION=…discogs…/release/NNNNNN`
shortcut), `### Still open` (D-19 `_done/` pruning).

#### 9b. `.planning/ROADMAP.md` Phase 5 criterion 2 — the D-12 in-band dated amendment

**Analogs:** `ROADMAP.md:262-272` (02.1-11) and `:526-549` (04-04, D-20). The four-move shape is
identical in both. Blockquoted, immediately under the criterion, never replacing it.

**The 02.1-11 example in full (`:262-272`) — the shorter, cleaner template:**

```markdown
     > **Amended 2026-09-03 by plan 02.1-11 (gap closure, CR-01).** This criterion previously read
     > "…the transcode quota and the five encoding values", which was false as implemented: the five
     > values were printed through `info()`, so `FAILURES` never incremented on drift and the check
     > printed its green tick regardless, while `quick-health-check.sh`'s selector omitted them
     > entirely. The **substance is kept, not reduced** — all five are now genuinely asserted rather
     > than two, and the verification report's alternative (assert two, reword "five" down to "two")
     > was **rejected**: … What changed in the wording is the ambiguity the verifier flagged:
     > **drift detection is now stated as drift detection**, and criterion 4 is named as the firing
     > proof it always was.
```

**The four moves, in order:**
1. `> **Amended <date> by plan <NN-NN> (<decision ref>).**`
2. **Quote the original wording** — `This criterion previously read "…"` / `The second clause reads
   "…", and it is **unsatisfiable as written**.`
3. **State the measurement that forces the change**, citing the artifact
   (04-04 cites `beets/importer/session.py` and `03-DECISION.md`; 02.1-11 cites the `info()` call).
4. **Name the change and assert substance is preserved** — the literal phrase used in both is
   **"The substance is kept, not reduced"**. Both also **name the rejected alternative** and why.

**Phase 5's instance** (one amendment, D-14 folded in as a one-line factual note per D-12/D-14):
- Original: *"Searching the download tree returns zero `_FAILED_`, `_UNPACK_` or stray `.rar` items
  outside `99-quarantine`, and the Harry Potter BluRay rip is out of `dj-mixes`."* (`ROADMAP.md:663-664`)
- Measurement: `05-PREMEASURE.md` § 5 — 10 `_FAILED_`/`_UNPACK_` under `complete/nzb/`, only **4**
  music; the other 6 are Sonarr's and Radarr's. `05-PREMEASURE.md` § 4 — `find` over `dj-mixes` for
  `*potter*` returns **zero**; the rip is at `complete/nzb/unsorted/Harry.Potter…MOOVEE`.
- Change: scope narrows to the music paths (`music/`, `unsorted/`, `dj-mixes/`, `lidarr-import/`,
  `_inbox/`); the Potter clause **names the wrong tree** and the item is ordinary junk taken through
  D-13's gate.
- Substance: the 6 TV/movie items are **not lost** — named in `05-PREMEASURE.md` § 5; the rejected
  alternative is quarantining another service's failures into a music-project folder, which would go
  red again on their next failure.

**Criteria 3 and 4 also drift from measurement** — the planner should decide whether each needs its
own amendment or a note: criterion 3 says *"split into per-volume folders"* against a folder with
**zero subdirectories** (`05-PREMEASURE.md` § 3), and its stated reconciliation target is **4760**
where D-08 asserts **4,746** mp3 with 14 sidecars accounted separately. Criterion 4 is already green
(D-22) and becomes an assertion.

#### 9c. `.planning/REQUIREMENTS.md` — the addendum shape

**Analog:** `REQUIREMENTS.md:276` (TAGR-05). Requirements use an **inline ADDENDUM inside the table
cell**, not a blockquote:

```markdown
| TAGR-05 | Phase 4 | Complete (Phase 4). **ADDENDUM 2026-09-11 (04-04, D-20/D-27)** — two
clarifications to the requirement text, neither of which reduces it. (1) **Scope:** … (2)
**Instrument:** … The text above is deliberately not rewritten. |
```
Key phrases to reuse: `**ADDENDUM <date> (<plan>, <decision>)**`, `neither of which reduces it`,
`The text above is deliberately not rewritten`. INBX-01 is at lines 159-160, INBX-02 at 161-162,
INBX-03 at 163-164.

---

## Shared Patterns

### Script conventions (apply to every new script)

**Source:** `scripts/freeze-music-apply.sh:67-124`, `scripts/spike03-image-headroom.sh:100-155`,
`scripts/snapshot-music-tags.sh:1-9`, `scripts/diff-music-tags.sh:53-61`

```bash
#!/usr/bin/env bash
# <name>.sh - <one-line purpose>
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull --ff-only`.
#   Host-resident because <reason it cannot be one ssh'd command>.
#
# Usage: / Workflow: / Outputs: / CONTRACT: / THE KEY (<decision id>): / Idempotent: /
# EXIT-CODE CONVENTION (stated here deliberately, not inherited) / HAZARD NOTES:

set -euo pipefail

ALL_CAPS_CONSTANT="${ALL_CAPS_CONSTANT:-default}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
```
(`freeze-music-apply.sh:116-124` uses the `ok()/warn()/err()/banner()` variant; either is house
style, but be consistent within a file. Note `fail()` **increments a counter** — that is the
"assert rather than report" mechanism, and `info()` is the one that does **not** and is therefore
the trap 02.1-11 amended a criterion over.)

**Self-documenting help** (`spike03-image-headroom.sh:149-154`) — the header block *is* `--help`,
so they cannot drift:
```bash
  -h|--help)
    grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
```

**Delivery is git** (`spike03-image-headroom.sh:10`, `normalise-dj-tags.py:25-32`, `DEPLOYMENT.md`):
*"Delivery is git: this repo is checked out at /mnt/fast/stacks and nothing else copies files in."*
A commit must reach `origin` before LXC 100 can `git pull --ff-only`. Never stage an untracked file
into `/mnt/fast/stacks/scripts` — an incoming commit adding the same path blocks the pull.

### The `/tmp` prohibition

**Source:** identical text in three scripts — `spike03-image-headroom.sh:91-93`,
`snapshot-music-tags.sh:68-72`, `freeze-music-apply.sh:64-65`, `diff-music-tags.sh:48-51`

```
# NOTHING is written to /tmp. /tmp on LXC 100 is a tmpfs and large files there consume host
# RAM (project MEMORY: 1.1 GB of EPG XML there took the whole 28 GB box down). All output goes
# to $OUT_DIR under /mnt/fast.
```
**Applies to:** the regenerated `Now!` inventory (explicitly, per `05-CONTEXT.md`), the approval
file, every NDJSON, every `zfs diff` capture. `diff-music-tags.sh:48-51` shows the variant when
scratch files are genuinely needed: *"created beside the BEFORE input - inside the fence - and
removed by an EXIT trap."*

### Execution environment — which host every task runs on

| Constraint | Evidence in repo | Consequence for the plan |
|---|---|---|
| `zfs` does not exist on LXC 100 | `freeze-music-apply.sh:78` (`ZFS_HOST` comment: *"the only place zfs exists"*), `:129-137` `detect_zfs_route()`; `normalise-dj-tags.py:123-127` | D-01 snapshot, `zfs diff`, `zfs list` → `ssh root@172.16.1.158` |
| `chown` fails from LXC 100 (sparse idmap, **not** aclmode) | `freeze-music-apply.sh:574-584`; `01-08-SUMMARY.md:20,42` (*"PROVEN: chown is impossible from LXC 100"*) | D-23 + D-24 chown → atlantis only |
| `chmod` fails EPERM on `tank` even as real root | `freeze-music-apply.sh:600-609`; `01-08-PLAN.md:14`; `CLAUDE.md` § Constraints | **Plan no mode change.** `0777` stays |
| `rsync -a` fails writing to `tank` (exit 23, stats look like success) | `freeze-music-apply.sh:60-62`, and `RSYNC_FLAGS="-rlt --no-p --no-o --no-g"` at `:79` | If any copy is needed, use those flags. D-07 is `rename(2)`, so ideally none is |
| `rsync`/`tmux`/`screen` not installed on LXC 100 | `05-CONTEXT.md` § Integration Points; `freeze-music-apply.sh:156-159` guards `command -v rsync` before using it | See § No Analog Found — the 209k-entry chown has no session-survival analog |
| `/tmp` on LXC 100 is tmpfs | four scripts, above | Everything durable under `/mnt/fast/` |
| A container-side `65534` is LXC 100's view, not the disk | `freeze-music-apply.sh:577-582`; `CLAUDE.md` § Constraints | Read ownership **from atlantis** before believing it |
| ZFS frees space asynchronously (~20 s lag) | `CLAUDE.md` § Constraints; `05-CONTEXT.md` § Integration Points | D-11's delete: assert path absence, not a `df` delta |
| `/mnt/fast/appdata` is not a real mountpoint; `/mnt/fast/spike-03` and `/mnt/fast/safety` are **not** on the `fast` ZFS pool | `normalise-dj-tags.py:200-203` (*"only the `mp` entries in /etc/pve/lxc/100.conf are real bind mounts"*) | Inventory output lands on LXC 100's **126 G ext4 root** — watch `df -h /`, not the pool |
| `ffprobe` takes one input file | `snapshot-music-tags.sh:308` (`-- "$f" </dev/null`); `05-CONTEXT.md` § Integration Points | Never `xargs -n 50 ffprobe` — it exits clean and produces nothing |
| beets has no `undo`; `mv` has no undo; `chown` has no undo | `05-PREMEASURE.md` § 2; `normalise-dj-tags.py:118-121` | D-01's snapshot is the only rollback, and it is enforced by a proof-file refusal |

### Assertion doctrine (README § Health Checks — the three rules)

**Source:** `normalise-dj-tags.py:748-750`, `quick-health-check.sh:822-825`, `:186-193`

1. **Fail closed, with "could not look" kept distinct from "nothing is wrong."**
   `quick-health-check.sh:822-825`: *"'Could not look', 'there are none' and 'BROKEN' are three
   different answers and this file's whole doctrine is that they must not share a verdict. They are
   now three branches."*
2. **Bound remote commands Linux-side.** `:437-442`: macOS has no GNU `timeout` (Homebrew installs
   it as `gtimeout`), so the bound executes on LXC 100 inside the remote command string — and is
   *probed for*, never assumed (`:689-701`).
3. **Assert rather than report.** `normalise-dj-tags.py:748`: *"'Assert rather than report' —
   README § Health Checks."* The mechanism is `fail()` incrementing `FAILURES`; `info()` does not,
   which is precisely the defect 02.1-11 amended a ROADMAP criterion over.

Plus two Phase-5-specific corollaries already in `05-CONTEXT.md` and evidenced above:
4. **Prove an assertion capable of failing** — driven negative control (D-21; and
   `quick-health-check.sh:463-487` is the written precedent).
5. **Pre-declare expected-but-odd observations** so a verifier meets a known list, not a discrepancy
   (D-04, Phase 4 D-31).

---

## No Analog Found

| Artifact / need | Role | Data flow | Reason |
|---|---|---|---|
| A **session-survival wrapper for the D-24 chown** over 209,039 entries | privileged long-running batch | ssh → recursive metadata write | `grep -rln 'nohup\|setsid' scripts/*.sh` returns **nothing**, and `tmux`/`screen` are not installed on LXC 100. The only analog, `freeze-music-apply.sh:594-596`, runs `ssh … "chown -R …"` **synchronously with no timeout** — fine at Phase 1's 2,674 entries, untested at ~74×. A dropped ssh mid-chown leaves a partially-normalised tree with no resume ledger. **The planner must decide**: run it from an atlantis-side shell (`pct`/console, not the LXC ssh path), split it into bounded batches with a ledger (the `snapshot-music-tags.sh:220-241` pattern applied to directories), or accept and document the exposure. Note this is a *host-side* run, so LXC 100's missing `tmux` is not necessarily binding — atlantis's toolset was not measured. |
| A **`Now!`-specific m3u parser** (D-02's map) | parser | file-I/O, transform | Nothing in `scripts/` parses an m3u. Nearest shape is `normalise-dj-tags.py:326-362` `derive_album_from_folder()` — regex extraction from a path string with an explicit `(value, None) \| (None, reason)` return and a named refusal reason per failure. Copy that **return contract** (a refusal is a recorded reason, never a silent skip) rather than any of its regexes. |
| An existing `_inbox` tree or any prior attempt | — | — | `05-PREMEASURE.md` § 7: nothing exists under `/mnt/tank/downloads`. Entirely greenfield; `mkdir` + `chown 568:568` from atlantis (D-23). |

---

## Metadata

**Analog search scope:** `scripts/` (26 files, 13,853 lines — all enumerated),
`.planning/phases/01-safety-harness-and-freeze-the-writers/` (01-08 PLAN + SUMMARY),
`.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`,
`stacks/selfhosted/arrs/beets.md`, `CLAUDE.md`.
**Files read in full or in targeted ranges:** 9.
**Strong analogs used:** 6 (`spike03-image-headroom.sh`, `normalise-dj-tags.py`,
`quick-health-check.sh`, `freeze-music-apply.sh`, `snapshot-music-tags.sh`, `diff-music-tags.sh`).
**Every analog named in `05-CONTEXT.md` was verified to exist at its stated path.**
**Pattern extraction date:** 2026-09-18
