---
phase: 03-tagger-spike
reviewed: 2026-09-04T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - scripts/normalise-dj-tags.py
  - scripts/spike03-discogs-probe.py
  - scripts/spike03-gen-import-config.sh
  - scripts/spike03-variant-survey.sh
  - scripts/spike03-wrtag-arms.sh
  - .gitignore
  - stacks/selfhosted/arrs/beets.md
findings:
  critical: 4
  warning: 19
  info: 9
  total: 32
status: issues_found
---

# Phase 3: Code Review Report

**Reviewed:** 2026-09-04
**Depth:** standard (per-file analysis, language-aware checks, cross-referenced against
`deferred-items.md` DEF-03-01..21)
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Five scripts and two supporting files. The code is unusually well-documented and several controls
in it are genuinely good — the probe's two-net redaction, the `signal.alarm()` ceiling, the
`assert_frame_set_unchanged()` backstop, the `manifest()` whole-subtree diff, and
`spike03-gen-import-config.sh`'s **source**-side token channel (mode gate, no argv, no echo, env
inheritance) are all correct as designed and worth keeping.

The defects cluster in three places, and all three are the *inverse* of a control that was
carefully built:

1. **The destination side of the token channel is unguarded** while the source side is exemplary.
   The token is written to `$DEST` before `chmod 600`, and nothing constrains `$DEST` to be outside
   the public git checkout.
2. **Two of this phase's own safety fences check a string, not a resolved path.** `wrtag-arms`'
   `find … -delete` guard and `normalise-dj-tags.py`'s scratch-root fence both pass on inputs that
   reach outside the fence — the first demonstrated below resolving to `/etc`.
3. **The "could not look ≠ nothing is wrong" rule that CLAUDE.md § Health Checks states, and that
   this phase logged four separate defects about (DEF-03-01, -03-11, -03-19, -03-20), is violated
   inside this phase's own wrote-nothing gate.**

Two credential findings deserve the operator's attention specifically, because this repository is
public and already pushed: CR-03 (`$DEST` mode race) and WR-19 (`beets.md`'s "every on-disk copy
was removed" claim, which is true of LXC 100 only and omits DEF-03-21's argv exposure and its four
surviving workstation copies).

Cross-referenced deferred items that are **still present in the shipped code** and are *not*
re-reported as new: DEF-03-09 (`normalise-dj-tags.py` WAV write path — see WR-12) and DEF-03-12
(the unnamed compose project — not in this file set).

---

## Critical Issues

### CR-01: `find "$LIB" -mindepth 1 -delete` is guarded by unresolved string prefixes, and `..` walks straight through both guards

**File:** `scripts/spike03-wrtag-arms.sh:251-255` (guards), `:187-192` (allow-list), `:120,129` (env-overridable inputs)

**Issue:** The script performs a recursive delete of everything under `$LIB`. It is guarded twice —
a `LIB_ALLOW_PREFIX` check and a literal `*/spike-03/*` component check — and the header argues at
length that this is "strictly stronger" than a deny-list and that `-delete` was chosen "so a bug
cannot turn into a recursive removal of an unexpected root".

Both guards are `case` patterns over the **unresolved** string. Neither calls `realpath`. `$LIB`
and `$LIB_ALLOW_PREFIX` are both `${VAR:-default}` and the header advertises `LIB` as a supported
env override. Demonstrated on this machine:

```
LIB="/mnt/fast/spike-03/wrtag-lib/../../../../etc"
allow-prefix guard: PASSED (would proceed)
spike-03 component guard: PASSED (would proceed)
-> find "$LIB" -mindepth 1 -delete would target: /etc
```

`find` resolves each `..` through the real filesystem, so the delete lands on the resolved path,
not the string that was checked. A trailing `/..` in a copy-pasted `LIB=` on LXC 100 — which is
exactly how the three arms are meant to be invoked — is sufficient. `2>/dev/null || true` on line
255 additionally silences whatever it could not delete.

**Fix:**

```bash
# Resolve BEFORE checking, and refuse if resolution moved the path.
LIB_REAL="$(realpath -m -- "$LIB")"
[ "$LIB_REAL" = "$LIB" ] || precheck_fail "LIB '$LIB' resolves to '$LIB_REAL' - pass the resolved path"
case "$LIB_REAL/" in
  "$LIB_ALLOW_PREFIX"*) : ;;
  *) precheck_fail "LIB '$LIB_REAL' is outside '$LIB_ALLOW_PREFIX' - refusing" ;;
esac
case "$LIB_REAL" in */spike-03/*) : ;; *) precheck_fail "no spike-03 component in '$LIB_REAL'" ;; esac
[ ! -L "$LIB" ] || precheck_fail "LIB is a symlink - refusing"
LIB="$LIB_REAL"
# and stop hiding the delete's own failures:
find "$LIB" -mindepth 1 -delete
```

Hardening `LIB_ALLOW_PREFIX` to a non-overridable constant (it is a *fence*, not a tunable) closes
the second half.

---

### CR-02: the wrote-nothing gate reports "0 files newer than the stamp" when `find` could not look

**File:** `scripts/spike03-wrtag-arms.sh:326-334`

**Issue:**

```bash
NEWER="$(find "$SRC" "$LIB" -newer "$STAMP" -type f 2>/dev/null || true)"
NEWER_COUNT="$(printf '%s' "$NEWER" | grep -c . || true)"
if [ "${NEWER_COUNT:-0}" -eq 0 ]; then
  ok "instrument 1 (find -newer, \$SRC and \$LIB): 0 files newer than the stamp"
```

`2>/dev/null` discards the error and `|| true` discards the exit code, so **every** failure mode of
`find` — `$SRC` gone, `$LIB` gone, a stale bind mount, EACCES on a subtree, the stamp deleted —
produces an empty `NEWER`, a zero count, and a green `ok` line saying the dry run wrote nothing.
This is the exact failure CLAUDE.md § Health Checks forbids ("fail closed with 'could not look'
kept distinct from 'nothing is wrong'"), inside the assertion this script exists to make, and the
realistic trigger is the one 03-05 finding 3 already recorded for this estate: a re-materialised
bind mount leaves the container/host pointed at a vanished inode.

The header claims four independent controls, and this is the one asserted first and quoted in the
per-arm evidence line.

**Fix:**

```bash
NEWER_RC=0
NEWER="$(find "$SRC" "$LIB" -newer "$STAMP" -type f 2>"$OUT/find-newer.err")" || NEWER_RC=$?
if [ "$NEWER_RC" -ne 0 ] || [ -s "$OUT/find-newer.err" ]; then
  bad "instrument 1 COULD NOT LOOK (find rc=$NEWER_RC) - this is not a pass:"
  sed 's/^/         /' "$OUT/find-newer.err"
  FAILED=1
elif [ "$(printf '%s' "$NEWER" | grep -c . || true)" -eq 0 ]; then
  ok "instrument 1: 0 files newer than the stamp"
else
  ...
fi
```

---

### CR-03: the Discogs token is written to `$DEST` **before** the file is chmod'ed 600, and a failed write leaves it there

**File:** `scripts/spike03-gen-import-config.sh:43` (`umask 077`), `:67-69` (write then chmod)

**Issue:** The source-side channel is correct — mode-gated env file, `export` of the name only, a
quoted heredoc, value read from `os.environ`, never in argv. The **destination** side is not:

```python
with open(dest, "w", encoding="utf-8") as fh:
    fh.write("".join(out))          # <-- token bytes land here
os.chmod(dest, 0o600)               # <-- mode is fixed only afterwards
```

`umask 077` governs the mode of a **newly created** file only. It has no effect on an existing one.
So:

* If `$DEST` already exists at `0644` (a prior run of an earlier version, a `cp`, an editor's
  backup, anything), `open(dest,"w")` truncates it and writes the live 40-character token into a
  world-readable file. On LXC 100 — 100+ containers, readable process table, and this phase's own
  DEF-03-04 precedent of exactly this exposure — the window lasts until `os.chmod` returns.
* If `fh.write()` or the `with` exit raises (ENOSPC on the ext4 root that
  `normalise-dj-tags.py`'s HAZARD NOTES and 03-03 finding 4 both warn about), **`os.chmod` never
  runs** and a partial, world-readable, token-bearing file is left on disk permanently. There is no
  `try/finally` and no `trap`.

The file header asserts "It lives outside the repository, is mode 600" — the mode half is only true
on the success path against a non-existent destination.

**Fix:** create the file with the right mode atomically, and never widen it:

```python
import os, tempfile
d = os.path.dirname(os.path.abspath(dest)) or "."
fd, tmp = tempfile.mkstemp(dir=d, prefix=".beets-import-", suffix=".yaml")  # mkstemp is 0600
try:
    os.write(fd, "".join(out).encode("utf-8"))
    os.fsync(fd)
finally:
    os.close(fd)
os.chmod(tmp, 0o600)
os.replace(tmp, dest)   # atomic; no window in which dest is both token-bearing and world-readable
```

(If the no-`tempfile` house rule from the sibling scripts is to be honoured, the minimal form is
`fd = os.open(dest, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)` followed by
`os.fchmod(fd, 0o600)` **before** the first write — the point is that the mode must be correct
before any token byte is written, not after.)

---

### CR-04: the D-07 scratch-root fence is applied to TARGET only; per-file writes are never re-checked

**File:** `scripts/normalise-dj-tags.py:609-629` (fence), `:686-693` (`collect_folders`), `:519-549` (`write_tags`), `:449-481` (`preserve_id3v1_trailer`)

**Issue:** `resolve_target_or_die()` correctly `realpath`s the TARGET and refuses anything outside
`/mnt/tank/downloads/spike-03`. The docstring calls this "the single most important behaviour in
the file" and names `/mnt/tank/media/Music` as the thing it exists to keep out.

The fence is then never applied again. `collect_folders()` walks the tree with `os.walk` (which
correctly does not descend symlinked *directories*) and returns every matching **file** name,
including symlinks. `write_tags()` calls `handle.save(path, …)` and `preserve_id3v1_trailer()`
opens `path` in `r+b` and seeks — both of which follow a symlink and write to its target. A single
symlink anywhere in the scratch tree pointing at `/mnt/tank/media/Music/...` defeats the fence
silently: the run reports a normal `changed` count and the NDJSON records the scratch path, not the
path that was actually written.

Reachability is reduced but not eliminated by how the tree happens to be built today
(GNU `cp -r` dereferences, so the reflinked copy contains regular files). It is not eliminated
because (a) the source is unattended usenet content on a live tree with an inflow (DEF-03-01,
DEF-03-18), (b) D-13 names this script as *the* normalisation tool for phases that will point it at
other trees, and (c) a hardlink into the library defeats it identically with no symlink involved.
A fence whose correctness depends on how a caller happened to create the tree is not a fence.

**Fix:** re-assert the fence at the write, where it is cheap and unconditional:

```python
def assert_inside_scratch(path: str) -> None:
    root = os.path.realpath(SCRATCH_ROOT)
    real = os.path.realpath(path)
    if not real.startswith(root + os.sep):
        raise RuntimeError(f"refusing to write outside {root}: {path} -> {real}")
    st = os.lstat(path)
    if stat.S_ISLNK(st.st_mode):
        raise RuntimeError(f"refusing to write through a symlink: {path}")
    if st.st_nlink != 1:
        raise RuntimeError(f"refusing to write a file with {st.st_nlink} links: {path}")

def write_tags(handle, path, changes):
    assert_inside_scratch(path)          # first line, before any save
    ...
```

Raising (rather than exiting) routes the refusal into the `.failed` ledger, which is the behaviour
the rest of the file already establishes.

---

## Warnings

### WR-01: a post-write assertion failure leaves the tag on disk but records no change

**File:** `scripts/normalise-dj-tags.py:830-873`

**Issue:** `write_tags()` performs the mutagen `save()` first (`:542`), then
`preserve_id3v1_trailer()` (`:543`) and `assert_frame_set_unchanged()` (`:544`). Both of the latter
can raise **after** the bytes are on disk. The caller treats any exception as a write failure:

```python
except Exception as exc:
    counts["failed"] += 1
    ...
    continue          # skips counts["changed"], skips changed_paths, skips the NDJSON emit
```

So a file whose ID3v2 tag was genuinely modified is reported as `written: <no record at all>` and
counted only in `failures`. Three instruments this phase depends on are then wrong at once: the
`sha256` equality between the dry-run and apply proposal sets (03-05's headline proof), DEF-03-10's
suggested "changed triples == proposed triples" gate, and the `.failed` ledger's implicit claim
that a failed file is an unmodified file. `preserve_id3v1_trailer()` raising is the worst case: the
ID3v1 block is left as mutagen regenerated it, so `audio_md5` has moved (DEF-03-03) on a file the
ledger says was never written.

**Fix:** emit the NDJSON record with an explicit state before re-raising, e.g. set
`written = "partial"` and write the record in the `except` branch too:

```python
except Exception as exc:
    counts["failed"] += 1
    record_change(out_fh, path, fields, written="unknown-post-save")   # the tag MAY be on disk
    failed_fh.write(json.dumps({..., "post_save": True}) + "\n")
    continue
```

and split the two post-save assertions from the save so the ledger can say which one fired.

### WR-02: `redact()` covers `logging` only — an unhandled traceback bypasses it, and the docstring says otherwise

**File:** `scripts/spike03-discogs-probe.py:342-347` (`RedactingFormatter`), `:196-198` (the claim), `:870-1104` (no `sys.excepthook`)

**Issue:** The SECURITY block states that `RedactingFormatter` "re-redacts the fully formatted
line, which is what covers a rendered traceback (`exc_text`)". That is only true for a traceback
that is *logged* with `exc_info=…`. This file never logs with `exc_info`. An exception that escapes
`main()` is rendered by `sys.excepthook` straight to stderr, entirely outside the logging stack.

The per-folder handler (`:970-990`) redacts correctly, and that is the highest-traffic path. The
uncovered surface is everything outside the folder loop: `bootstrap_beets()` (where
`config["discogs"]["user_token"]` has just been set and any beets/`discogs_client` construction
error can surface a repr), `read_folder_meta()`, the `finally` block, and the window between
`configure_logging()` at `:872` and `require_env()` at `:886` where net 2 (`SECRETS`) is still
empty. `discogs_client` exceptions carry the `?token=` URL — that is the whole premise of
DEF-03-04.

**Fix:** install a redacting excepthook immediately after `configure_logging()`:

```python
def _redacting_excepthook(etype, value, tb):
    import traceback
    sys.stderr.write(redact("".join(traceback.format_exception(etype, value, tb))))
sys.excepthook = _redacting_excepthook
```

and register `SECRETS` before anything that can raise with a token in it — i.e. call
`require_env()` before `configure_logging()`, or split the env read out and register the value
first.

### WR-03: `--verbose` turns the ROOT logger to DEBUG — the exact thing the SECURITY block says the file never does

**File:** `scripts/spike03-discogs-probe.py:445`, contradicting `:204-206`

**Issue:** `root.setLevel(logging.DEBUG if verbose else logging.INFO)`. The docstring states the
file "never calls `logging.basicConfig(level=DEBUG)` on the ROOT logger, because that would enable
DEBUG for every library in the process (03-RESEARCH.md V7, ASVS V7)". `--verbose` achieves the
identical effect by a different call. The redacting handler still covers records that reach it, but
the stated control ("DEBUG on for exactly one logger") is not what the code does, and any library
that attaches its own handler with `propagate=False` is outside the redaction entirely.

**Fix:** scope `--verbose` to this script's own logger, and say so:

```python
root.setLevel(logging.INFO)
logging.getLogger("spike03-probe").setLevel(logging.DEBUG if verbose else logging.INFO)
```

If a genuine root-DEBUG mode is wanted, gate it behind a separate flag whose help text names the
credential consequence.

### WR-04: nothing stops `$DEST` being inside the public git checkout

**File:** `scripts/spike03-gen-import-config.sh:27,67`

**Issue:** The header asserts as a property that the generated file "lives outside the repository",
and CLAUDE.md/`beets.md` both record that this repository is public with one credential exposure
already recoverable via `git log -S`. Nothing enforces it: `$DEST` is `$2`, unvalidated, and
`/mnt/fast/stacks` (the checkout) is on the same host. `.gitignore` has no pattern that would catch
a generated beets config (`**/.env`, `**/secrets/*`, `**/data/*`, `**/config/*/secrets/*`,
`*.env.backup`), so a mistyped second argument produces a token-bearing, committable, untracked
file inside a public repo.

**Fix:**

```bash
DEST_REAL="$(realpath -m -- "$DEST")"
if git -C "$(dirname "$DEST_REAL")" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "REFUSING: $DEST_REAL is inside a git worktree - this file carries a live token" >&2
  exit 2
fi
case "$DEST_REAL" in /mnt/fast/spike-03/*|/mnt/fast/secrets/*) : ;;
  *) echo "REFUSING: $DEST_REAL is outside the allowed output roots" >&2; exit 2 ;; esac
```

### WR-05: the token is injected into YAML unquoted

**File:** `scripts/spike03-gen-import-config.sh:61,65`

**Issue:** `out.append(f"  user_token: {token}\n")`. A value containing `#`, a leading `&`/`*`/`!`,
a `: ` sequence, or leading/trailing whitespace is silently mis-parsed by YAML — `#` truncates the
value at the comment, whitespace is stripped. beets then holds a *wrong* token, and unlike
`spike03-discogs-probe.py` (which refuses the whole run on a non-200 identity probe, refusal 2)
`beet import -t` has no such gate: every folder simply returns no Discogs candidate. That is
precisely the "0% by construction" artefact the probe's three refusals were built to prevent, on
the cross-check instrument that T1's agreement claim rests on.

**Fix:** emit a quoted scalar and reject a value that cannot be represented:

```python
if "\n" in token or "\r" in token:
    raise SystemExit("token contains a newline - refusing")
out.append('  user_token: "%s"\n' % token.replace("\\", "\\\\").replace('"', '\\"'))
```

### WR-06: the `discogs:` insertion is an exact string match, and the fallback creates the duplicate key the comment warns about

**File:** `scripts/spike03-gen-import-config.sh:60-65`

**Issue:** The comment says a duplicate top-level key "would silently override
index_tracks/search_limit, and the `index_tracks` setting is exactly what the strict D-05 rule is
stated against". The guard is `ln.rstrip("\n") == "discogs:"` — an exact match that fails on a
trailing space, an inline comment, CRLF line endings (`\r` survives `rstrip("\n")`), or any
indentation. On failure `if not injected:` appends a **second top-level `discogs:` block**, doing
exactly what the comment forbids. The run still exits 0; the only signal is
`token injected=False` in one line of stdout.

**Fix:** treat a missed insertion as a hard failure, and match tolerantly:

```python
if not injected and ln.rstrip().rstrip("\r") == "discogs:" and not ln.startswith((" ", "\t")):
    ...
if not injected:
    raise SystemExit(f"REFUSING: no top-level `discogs:` block in {base} - "
                     "appending one would create a duplicate key and override index_tracks")
```

### WR-07: the summary counters do not partition the file set

**File:** `scripts/normalise-dj-tags.py:779,806,823-824,881-896`

**Issue:** `counts["skipped"]` is incremented for a rule-1 skip (`:779`) and the file then also
falls through to `counts["unchanged"] += 1` (`:824`). Rule 3's folder-level skip adds
`len(loaded)` (`:806`) for files that may separately be counted `changed`. So
`files_seen != changed + unchanged + skipped + failed`, and `skipped` mixes a per-file event with a
per-folder one. The 03-05 run happened to have `skipped == 0`, which is why it was not noticed;
the numbers this script produces are the phase's evidence.

**Fix:** count each file exactly once with an explicit disposition, and report skip *reasons*
separately:

```python
counts["disposition_changed" | "disposition_unchanged" | "disposition_failed"] += 1
skip_reasons[reason] += 1      # diagnostic, not a partition member
```
then assert `files_seen == changed + unchanged + failed` before printing the summary.

### WR-08: rule 1 collapses a multi-issue folder to its first issue number

**File:** `scripts/normalise-dj-tags.py:296-303`

**Issue:** `re.search(r"\b(\d{1,4})\b", tail[series_end:])` takes the first 1–4 digit run and has no
concept of a range. Verified:

```
derive_album_from_folder("VA-Mastermix.Crate.068-070-2025") -> ("Mastermix Crate 068", None)
```

That folder is real — DEF-03-16 records it as 60 files spanning **three** crates. Rule 1 fires only
on an empty `album`, which is exactly the state DEF-03-16 measured on ~40% of Mastermix folders. So
the tool would write `Mastermix Crate 068` onto all 60 files and hand Discogs a query whose track
count (60) cannot match the release (20) — a confidently wrong album value written into audio, on
the one rule that touches files with no prior album to compare against.

**Fix:** detect a range and refuse rather than guess, since a wrong album is worse than no album
(CLAUDE.md § Autotagging ceiling):

```python
mrange = re.match(r"\s*(\d{1,4})\s*[-–]\s*(\d{1,4})\b", tail[series_end:])
if mrange:
    return None, "issue_range_needs_split"
```

### WR-09: `canonicalise_album()` does not always reach rule 1's canonical form, which its own docstring says is the invariant

**File:** `scripts/normalise-dj-tags.py:311-331`, `:214-218`

**Issue:** The docstring states the target form is "the SAME form rule 1 produces —
`<Label> <Series> <NNN>` — because a canonicalisation that lands somewhere else than the derivation
would leave the two halves of the sample carrying two different album shapes into the same Discogs
query." Verified counter-examples:

```
canonicalise_album("Mastermix Vol. 5 Disc 1") -> "Mastermix 5 Disc 1"
```

`VOL_NOISE_RE` removes the only series token, and `TRAILING_DISC_RE` requires a `-`/`–` before
`Disc`, so a space-separated `Disc 1` survives. The result is a bare label plus a number — the
"resolves the LABEL, not the release" degenerate shape that `spike03-variant-survey.sh:334-348`
widened V5 specifically to catch, produced here *by the normaliser itself*.

**Fix:** re-validate the canonical output against the same shape rule 1 must satisfy, and leave the
value alone (or skip the file) when it does not:

```python
CANONICAL_RE = re.compile(
    r"^(" + "|".join(map(re.escape, LABELS)) + r")\s+(" +
    "|".join(map(re.escape, SERIES)) + r")\s+\d{1,4}$", re.IGNORECASE)
canonical = canonicalise_album(album)
if canonical != album and not CANONICAL_RE.match(canonical):
    counts["skipped"] += 1
    log.warning("rule 2 skipped %s: canonical form %r is not <Label> <Series> <NNN>", path, canonical)
    continue
```
Also make `TRAILING_DISC_RE` separator-optional: `r"\s*[-–]?\s*Disc\s*\d+\s*$"`.

### WR-10: the snapshot proof has no freshness or authenticity bound

**File:** `scripts/normalise-dj-tags.py:632-678`

**Issue:** `--apply` is refused unless a file *contains the literal string*
`tank/downloads@spike-03-t0`. Any file containing that string satisfies it — including one written
days earlier, or one produced by `echo`. The `route:` line is parsed for the banner but is not
required and is not verified. The docstring is emphatic that this snapshot "is its only rollback",
which makes a stale proof (snapshot since destroyed, or a proof taken before an intervening
snapshot rotation) an unbacked write.

**Fix:** bound the proof and require the route to be recorded:

```python
age = time.time() - os.path.getmtime(proof_path)
if age > 3600:
    ... "REFUSING TO APPLY: snapshot proof is %.0f minutes old; re-take it" ... ; sys.exit(2)
if route == "unrecorded in the proof file":
    ... "REFUSING TO APPLY: the proof file does not record how it was produced" ...; sys.exit(2)
```

### WR-11: raw on-disk tag values are interpolated into stdout and log lines unescaped

**File:** `scripts/normalise-dj-tags.py:827-829`, `:751`, `:779`, `:806`, `:837`

**Issue:**

```python
sys.stdout.write(f"{path} :: {field}: {'<MISSING>' if old is None else old} -> {new}\n")
```

`old` is the value read from an untrusted downloaded file. A tag containing `\n` breaks the
one-line-per-change contract that the dry-run review artefact is read from (D-08 makes the dry run
*the* review artefact), and a tag containing ANSI escapes is written straight to the reviewer's
terminal. `log.error("read failed %s: %s", path, …)` and the two `log.warning` calls have the same
property for paths. Only the NDJSON path is safe, because `json.dumps` escapes.

**Fix:** sanitise the human-readable line the same way `sanitise_derived()` already sanitises
derived values:

```python
def display(v):
    return "<MISSING>" if v is None else CONTROL_RE.sub("?", str(v))
sys.stdout.write(f"{path} :: {field}: {display(old)} -> {display(new)}\n")
```

### WR-12: DEF-03-09 is still present, and its **read** half makes a WAV dry run report a clean zero

**File:** `scripts/normalise-dj-tags.py:426-436` (read), `:547-549` (write)

**Issue:** Cross-reference to DEF-03-09, which is logged and deliberately unfixed — not re-reported
as new. Flagged here because the code still ships it and because the deferred entry emphasises the
loud half while the quiet half is the more dangerous one for a *future* caller.

The write half fails loudly (134/134 `TypeError`, exit 1). The **read** half does not:
`mutagen.File(path, easy=True)` on a WAVE yields a raw `ID3` keyed by frame id, so
`handle.tags.get("album")` returns `None` for the 87 WAV that do carry an album. A **dry run** over
a WAV tree therefore prints `files that would change: 0` and exits 0 — reporting "nothing to do"
where the truth is "could not read". DEF-03-09 measured `files that would change: 0` and attributed
it to the rules not firing; both causes produce the same number and the run cannot distinguish
them.

**Fix (with the DEF-03-09 fix, Phase 4):** branch on WAVE explicitly in `read_tags()` as well as
`write_tags()`, and make an unreadable container a `.failed` record rather than a `None` value:

```python
if path.lower().endswith((".wav", ".wave")):
    import mutagen.wave
    w = mutagen.wave.WAVE(path)
    if w.tags is None:
        w.add_tags()
    values = {f: (w.tags.getall(FIELD_FRAME[f])[0].text[0]
                  if w.tags.getall(FIELD_FRAME[f]) else None) for f in WRITABLE_FIELDS}
    return w, values
```

### WR-13: `diff_manifest` reports "identical before and after" when `diff` could not compare

**File:** `scripts/spike03-wrtag-arms.sh:340-350`

**Issue:** `d="$(diff "$b" "$a" || true)"` then `if [ -z "$d" ]; then ok "identical"`. `diff` exits
**2** on trouble (missing file, unreadable file) and writes to stderr, leaving stdout empty — which
this reads as "identical". The header calls instrument 2 the strong one precisely because
instrument 1 is weak; with CR-02 this means both wrote-nothing instruments can pass vacuously in
the same run.

**Fix:**

```bash
d="$(diff "$b" "$a")"; rc=$?
if [ "$rc" -eq 0 ]; then ok "..."; return 0; fi
if [ "$rc" -ne 1 ]; then bad "instrument 2 (${1}.${2}): diff could not compare (rc=$rc)"; return 1; fi
```

### WR-14: enumeration errors are discarded in two places in the survey

**File:** `scripts/spike03-variant-survey.sh:213` (`.covers` probe), `:294` (live-route find)

**Issue:** Both `find` invocations end `2>/dev/null`. A permissions failure, a stale mount, or a
vanished tree silently under-counts: the `.covers` union quietly loses scan-bearing folders (which
D-06 uses to *exclude* folders from the draw), and the live route quietly enumerates fewer files
than exist. Neither changes an exit code. The script's own header (`:88-92`) commits to exit 2 on
"a missing/unreadable fence or capture" and this is the same class one level down.

**Fix:** capture stderr and fail on it, or at minimum surface it:

```bash
find "$NZB/$t" -mindepth 2 -maxdepth 2 -type d -name '.covers' -printf '%h\n' 2>"$OUT_DIR/.covers.err"
[ -s "$OUT_DIR/.covers.err" ] && { fail "could not enumerate .covers under $NZB/$t"; cat "$OUT_DIR/.covers.err" >&2; exit 2; }
```

### WR-15: the survey's V5 noise definition is narrower than the normaliser's rule 2, so the strata weights and the tool disagree

**File:** `scripts/spike03-variant-survey.sh:363-369` (`noisy()`), vs `scripts/normalise-dj-tags.py:219-221,325-330`

**Issue:** `noisy()` tests `^Mastermix - ` only. `LABEL_SEPARATOR_RE` in the normaliser is built
from `LABELS = ("Mastermix", "DMC")` and therefore also fires on `DMC - `. Verified:

```
canonicalise_album("DMC - Issue 12") -> "DMC Issue 12"     # rule 2 fires
```

A `DMC - Issue NNN` folder is classified **V1** ("ONE consistent non-placeholder artist … with a
clean album", i.e. already the good case), contributes its weight there, and is excluded from V5 —
while the normaliser will change it. The strata weights are what T1's weighted roll-up multiplies
its per-stratum rates by, and DEF-03-08 already records that V1 "admits album strings that are
clean but identify no release". This is a second, independent instance of that with a mechanical
cause: two definitions of "noisy" in two files.

**Fix:** derive the survey's `noisy()` from the same label list rather than hard-coding one label:

```jq
or ($s | test("^(Mastermix|DMC) - "))
```

and, better, have both read one shared constant so the definitions cannot drift again.

### WR-16: the live route parses `find -print` through `read -r`

**File:** `scripts/spike03-variant-survey.sh:294`

**Issue:** `done < <(find "$NZB/$t" -type f "${FIND_EXPR[@]}" -print 2>/dev/null | LC_ALL=C sort)`.
Every other enumeration in this file uses `-print0` + `sort -z` + `xargs -0` (`:259-261`), correctly.
This one does not, so a filename containing a newline is split into two paths. The real folder names
here contain spaces, `&` and `:` (all safe with `IFS= read -r`), but the inconsistency is with the
file's own house style and the failure would be silent.

**Fix:** `while IFS= read -r -d '' f; do … done < <(find … -print0 | LC_ALL=C sort -z)`.

### WR-17: unvalidated `--album` reaches the container as a path

**File:** `scripts/spike03-wrtag-arms.sh:16,199-201,289`

**Issue:** The usage text says `--album` is "A directory name directly under `$SRC`. Not a path -
just the folder name." Nothing enforces that. `[ -d "$SRC/$ALBUM" ]` succeeds for `../..`, and
`"/music/source/$ALBUM"` is then passed to wrtag, which resolves it inside the container — pointing
the tool at the container root rather than at an album. The `:ro` mount bounds the damage to a
wrong measurement rather than a write, but the arm would silently be measuring something else.

**Fix:**

```bash
case "$ALBUM" in */*|.|..|"") precheck_fail "--album must be a single directory name, not a path: '$ALBUM'" ;; esac
```

### WR-18: `mutagen`'s `v1=` save option is not set explicitly, unlike the other two

**File:** `scripts/normalise-dj-tags.py:542-543`, vs the CONTRACT block at `:80-96`

**Issue:** The CONTRACT states three mutagen defaults "quietly broaden the write past `album` and
`artist`" and that "each is set explicitly at the line it matters". Two are — `v2_version` and
`load_v1` at `:416`. The third is not: `handle.save(path, v2_version=…)` leaves `v1` at mutagen's
default (`ID3v1SaveOptions.UPDATE`), and the regeneration is *undone afterwards* by
`preserve_id3v1_trailer()`. That is a repair, not a prevention, and it leaves a window in which the
on-disk ID3v1 block is wrong — a crash or a kill between `:542` and `:543` leaves the file with a
moved `audio_md5` and no record (compounding WR-01).

**Fix:** prevent as well as repair —
`handle.save(path, v1=mutagen.id3.ID3v1SaveOptions.REMOVE if id3v1_before is None else mutagen.id3.ID3v1SaveOptions.UPDATE, v2_version=…)`
is not sufficient on its own; the correct minimal form is to keep `preserve_id3v1_trailer()` **and**
document that `v1` is deliberately left at UPDATE, so the docstring's "all three are set
explicitly" claim matches the code.

### WR-19: `beets.md`'s credential paragraph under-states a live exposure, in a public document

**File:** `stacks/selfhosted/arrs/beets.md:1004-1013`

**Issue:** The Standing Action paragraph gives three causes ("a `644` file by a logging path", "an
ad-hoc verification command", "an agent transcript") and asserts *"Every on-disk copy was removed
and verified gone at Phase 3 close."*

`deferred-items.md` DEF-03-21 records a **fourth** cause that this paragraph does not mention — the
token passed as a command-line argument, world-readable via `/proc/<pid>/cmdline` for ~45 minutes
on a host running 100+ containers, then rendered by `pgrep -af` — and explicitly says the action
"goes to project close carrying **all four** causes, so whoever executes it does not act on the
one-cause problem DEF-03-04 opened." It also records **four plaintext copies still present on the
workstation** at Phase 3 close, three of them append-only transcripts and one whose deletion was
refused by policy (`bla6jts0m.txt`, 131,433 bytes).

"Every on-disk copy was removed and verified gone" is true of LXC 100 and false of the workstation.
This is the document a future reader will consult when deciding how urgent rotation is.

**Fix:** restate to match DEF-03-21:

```markdown
**Rotate the Discogs personal access token at project close.** Four independent causes, one of
them a world-readable process argv (`/proc/<pid>/cmdline`) for ~45 minutes on LXC 100. Every copy
**on the estate** was removed and verified gone at Phase 3 close and
`/mnt/fast/secrets/discogs.env` is the single remaining one at `600 root`. **Four plaintext copies
survive on the operator's workstation** — local and unpublished, three of them append-only agent
transcripts that cannot be reliably scrubbed. Rotation, not deletion, is the effective remedy.
This repository is provably clean (screened by value and by 8-character prefix, 0 hits).
```

---

## Info

### IN-01: dead length check after truncation

**File:** `scripts/normalise-dj-tags.py:252-259`
**Issue:** `v = v[:MAX_ALBUM_LEN]` is followed by `if len(v) > MAX_ALBUM_LEN: return None`, which is
unreachable. Verified: an over-length input is rejected by the *digit* check instead (truncation
removes the issue number), which is the correct outcome by accident, not by the stated rule.
**Fix:** validate length before truncating, or drop the check and say so.

### IN-02: earliest-label selection compares a start offset against an end offset

**File:** `scripts/normalise-dj-tags.py:277-281`
**Issue:** `if m and (label_end is None or m.start() < label_end)` — the intent is "the earliest
label wins", but the comparison is against the previous match's `end()`. Harmless with the current
two non-overlapping labels; wrong the moment a third overlapping label is added.
**Fix:** track `label_start` and compare `m.start() < label_start`.

### IN-03: `--dry-run` is parsed and never read

**File:** `scripts/normalise-dj-tags.py:575-579`, `:704`
**Issue:** `applying = bool(args.apply)`; `args.dry_run` is never consulted. Correct behaviour
(the flags are mutually exclusive and dry-run is the default), but the flag is decorative.
**Fix:** none required; optionally assert `not (args.dry_run and args.apply)` for symmetry with the
documented contract.

### IN-04: `--out` truncates prior evidence and neither handle is in a `try/finally`

**File:** `scripts/normalise-dj-tags.py:732-734`, `:925-928`
**Issue:** `open(args.out, "w")` destroys a previous run's NDJSON silently. If an exception escapes
the folder loop, `out_fh`/`failed_fh` are never closed and `.summary.json` is never written, so a
crashed run leaves no summary. `out_fh.flush()` per record limits the loss.
**Fix:** open with `"x"` (or refuse an existing path), and wrap the loop in `try/finally`.

### IN-05: `--folders-from` and `--ledger` open failures exit 1, not the documented 2

**File:** `scripts/spike03-discogs-probe.py:876`, `:919-920`
**Issue:** The exit-code convention reserves 2 for "usage error, a missing environment variable…".
A missing `--folders-from` file or an unwritable ledger directory raises an unhandled `OSError`,
which Python exits 1 for — indistinguishable from "one or more folders failed".
**Fix:** wrap both in `try/except OSError` and `return 2` with a named message.

### IN-06: a signal during the final folder yields exit 1 on a run that completed

**File:** `scripts/spike03-discogs-probe.py:959`, `:1092-1096`
**Issue:** `STATE.stop` is set by the handler; the loop-top `break` never runs because the loop
ends naturally, but `if STATE.stop: return 1` still fires with "interrupted at a folder boundary".
Fails in the safe direction, but a fully-completed run is reported as partial.
**Fix:** `if STATE.stop and (probed + skipped + failures) < len(folders): return 1`.

### IN-07: `${YES:+passed}${YES:-not passed}` prints `passed1`

**File:** `scripts/spike03-wrtag-arms.sh:242`
**Issue:** When `YES=1`, both expansions produce output: `passed` then `1`. Cosmetic, but the banner
is copied into the evidence file.
**Fix:** `say "  low-score -yes   : $([ -n "$YES" ] && echo passed || echo 'not passed')"`.

### IN-08: both wrote-nothing instruments are `-type f` only

**File:** `scripts/spike03-wrtag-arms.sh:268-272`, `:326`
**Issue:** A directory created under `$SRC` would be invisible to `find -newer -type f` and to both
manifests. `$LIB` is covered by the separate `LIB_AFTER` entry count (`:357`); `$SRC` is covered
only by the `:ro` mount.
**Fix:** drop `-type f` from the `-newer` instrument, or add a `-type d` manifest line.

### IN-09: `beets.md` carries two figures superseded elsewhere in this phase

**File:** `stacks/selfhosted/arrs/beets.md:59`, `:118`, `:155`
**Issue:** (a) `music` is listed as **275** files; `spike03-variant-survey.sh:68-76` records two
independent instruments returning **24 folders / 277 files** and prints the correction at run time.
(b) "Mastermix, DMC, Music Factory, Crate, Toolkit and Essential Hits are **not** in MusicBrainz …
Autotagging cannot succeed" and bucket C's "Never going to autotag" contradict CLAUDE.md
§ *Autotagging ceiling* (~46 MusicBrainz entries do exist, mostly 5–10-track stubs) and 03-07's
measured MusicBrainz candidate sets. The § *Phase 3* section corrects the Discogs half but does not
retract this, and the overstatement removes the stated reason for the mandated track-count check.
**Fix:** update `275 → 277 (24 folders, 2026-09-03)` with its date per DEF-03-18's ruling, and
reword to *"present in MusicBrainz only up to ~2016 and frequently as 5–10-track stubs — which is
worse than absence; never accept a match without a track-count check."*

---

_Reviewed: 2026-09-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
