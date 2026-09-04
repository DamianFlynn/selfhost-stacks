#!/bin/bash
# Plan 03-07 (T-03-37): generate the `beet import -t` runtime config for the criterion-1
# cross-check.
#
# This is the ONLY file in Phase 3 that contains the Discogs token in plaintext. It lives
# outside the repository, is mode 600, and is deleted in plan 03-11.
#
# "is mode 600" is an invariant on EVERY path through this script, not only the happy one -
# see the CR-03 block at the bottom. It is created 0600 before the first token byte is
# written and moved into place atomically, so no failure - including a pre-existing 0644
# destination or an ENOSPC mid-write - can leave a world-readable file carrying the token.
#
# "lives outside the repository" IS ENFORCED TOO (WR-04). It used to be a property this header
# asserted and nothing checked: $DEST is $2, it was unvalidated, and the checkout itself
# (/mnt/fast/stacks) is on the same host as every legitimate destination. .gitignore carried no
# pattern that would catch a generated beets config, so a mistyped second argument produced a
# TOKEN-BEARING, COMMITTABLE, UNTRACKED file inside a PUBLIC repository - one that already has
# a credential exposure recoverable via `git log -S`. CR-03 fixed the mode; it did not fix the
# location, and 0600 does not help once a file is committed. The check is now a REFUSAL, runs
# BEFORE the credential file is read, and is backed by a narrow .gitignore pattern as defence in
# depth. See the WR-04 block below.
#
# THE POINT OF THIS SCRIPT IS THE CHANNEL THE TOKEN TRAVELS ON.
# The value is never interpolated into an `echo`, a `printf` argument, a heredoc typed at a
# prompt, a `docker exec -e`, or any other argv. LXC 100 runs 100+ containers with a readable
# process table, and anything typed at an interactive prompt lands in `.bash_history`
# permanently. The repository is PUBLIC and one prior credential exposure in it is still
# recoverable via `git log -S`.
#
# The token reaches the generated file by exactly one route: this script `source`s the
# 600-root-gated env file, `export`s the NAME only (never the value), and a Python child reads
# it back out of its own `os.environ`.
#
# DEF-03-04: the Discogs token is sent as a `?token=` QUERY PARAMETER, not an Authorization
# header, so anything that logs request lines is a credential sink. Screen by VALUE, from
# inside the container, printing only counts.
#
# usage: spike03-gen-import-config.sh <base-config> <output-config>
set -euo pipefail

BASE="${1:?usage: $0 <base-config> <output-config>}"
DEST="${2:?usage: $0 <base-config> <output-config>}"
ENV_FILE="${DISCOGS_ENV_FILE:-/mnt/fast/secrets/discogs.env}"

# --- WR-04: refuse a $DEST inside any git working tree -------------------------------------
# Deliberately the FIRST check in the script. It runs before the credential file is gated, read
# or exported, so a bad destination is refused while the token is still only on disk in one
# 600-root file. A guard placed after the read would already have the value in this process's
# environment when it fired.
#
# The repo root is DETECTED, never hard-coded: `git rev-parse --show-toplevel` finds the real
# checkout wherever it is - /mnt/fast/stacks on LXC 100, a clone anywhere else, or a linked
# worktree - and a hard-coded path would be one more thing to keep in sync with reality. It also
# means the guard covers repositories this script has never heard of.
#
# Resolution is CR-01's approach, verbatim, so both scripts resolve paths the same way: GNU
# `realpath -m` first (it resolves components that do not exist yet, which $DEST usually does
# not), python3's os.path.realpath as the fallback, and a REFUSAL if neither is available.
# Checking an unresolved string here would be the CR-01 defect a second time: `..` and symlinks
# both walk a string guard straight into the checkout.
#
# It sets a GLOBAL rather than echoing its result, exactly as the sibling script does. That is
# not a style choice: `exit` inside a `$( )` leaves only the subshell, so a refusal returned
# that way would depend on `set -e` to stop the script - and a guard whose refusal is
# conditional on an option staying set is not a guard.
RESOLVED=""
resolve_or_die() { # $1 = label  $2 = path -> sets RESOLVED
  local label="$1" path="$2" r=""
  if [ -z "$path" ]; then
    echo "REFUSING: $label is empty" >&2
    exit 2
  fi
  if r="$(realpath -m -- "$path" 2>/dev/null)" && [ -n "$r" ]; then
    :
  elif r="$(python3 -c 'import os,sys; sys.stdout.write(os.path.realpath(sys.argv[1]))' \
              "$path" 2>/dev/null)" && [ -n "$r" ]; then
    :
  else
    echo "REFUSING: $label '$path' could not be resolved: no working 'realpath -m' and no" >&2
    echo "  python3. Refusing rather than checking the unresolved string - that is CR-01." >&2
    exit 2
  fi
  RESOLVED="$r"
}

resolve_or_die "the output path" "$DEST"
DEST_REAL="$RESOLVED"

# `git -C` needs a directory that EXISTS, and $DEST's parent may not. Walk up to the nearest
# existing ancestor rather than letting a non-existent parent make the check silently pass:
# "could not look" must not read as "not in a repository" (CLAUDE.md § Health Checks).
GIT_PROBE_DIR="$(dirname -- "$DEST_REAL")"
while [ ! -d "$GIT_PROBE_DIR" ] && [ "$GIT_PROBE_DIR" != "/" ]; do
  GIT_PROBE_DIR="$(dirname -- "$GIT_PROBE_DIR")"
done

if ! command -v git >/dev/null 2>&1; then
  echo "REFUSING: git is not available, so it cannot be checked whether" >&2
  echo "  '$DEST_REAL' is inside a repository. This file carries a live Discogs token and the" >&2
  echo "  checkout is PUBLIC; an unperformed check is not a passed check." >&2
  exit 2
fi

# GIT_DIR/GIT_WORK_TREE are unset for the probe so an ambient value inherited from a caller
# cannot point the check at a different repository than the one containing $DEST. Their most
# dangerous form is a bare repo, where --show-toplevel errors and the check would FAIL OPEN.
if DEST_REPO="$(unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR
                git -C "$GIT_PROBE_DIR" rev-parse --show-toplevel 2>/dev/null)" \
   && [ -n "$DEST_REPO" ]; then
  echo "REFUSING: '$DEST_REAL' is inside the git working tree at '$DEST_REPO'." >&2
  echo "  This file carries a LIVE Discogs token in plaintext. This repository is PUBLIC, and a" >&2
  echo "  committed credential stays recoverable via 'git log -S' long after it is deleted." >&2
  echo "  Mode 0600 does not help a file once it is committed. Write it outside the checkout -" >&2
  echo "  /mnt/fast/spike-03/ is where this phase's generated configs belong." >&2
  exit 2
fi

# NOTE ON SCOPE: the review also suggested an allow-list of output roots. Not taken here - it
# would hard-code paths this script is deliberately free of, and the committable-credential
# hazard WR-04 is about is fully addressed by the refusal above plus the .gitignore pattern.

# --- gate the credential file before reading it ------------------------------------------
mode_owner="$(stat -c '%a %U' "$ENV_FILE")"
if [ "$mode_owner" != "600 root" ]; then
  echo "REFUSING: $ENV_FILE is '$mode_owner', expected '600 root'" >&2
  exit 2
fi

# NO `set -a`. Sourcing sets a shell variable; the `export` below promotes the NAME only.
# shellcheck disable=SC1090
. "$ENV_FILE"
: "${DISCOGS_USER_TOKEN:?DISCOGS_USER_TOKEN not set by $ENV_FILE}"
export DISCOGS_USER_TOKEN

umask 077

# The Python child reads the value from its OWN environment. The value is not an argument to
# this call, and it is not present anywhere in this file.
#
# It is handed $DEST_REAL, not $DEST, so the path that was CHECKED is the path that is WRITTEN
# (WR-04). They differ when the final component is a symlink: `os.replace()` would replace the
# symlink itself, landing the file at $DEST while the guard had cleared its target elsewhere.
BASE="$BASE" DEST="$DEST_REAL" python3 - <<'PY'
import os

base, dest = os.environ["BASE"], os.environ["DEST"]
token = os.environ["DISCOGS_USER_TOKEN"]

lines = open(base, encoding="utf-8").read().splitlines(keepends=True)
out, injected = [], False
for ln in lines:
    out.append(ln)
    # Insert into the existing `discogs:` block rather than appending a second one - a
    # duplicate top-level key would silently override index_tracks/search_limit, and the
    # `index_tracks` setting is exactly what the strict D-05 rule is stated against.
    if not injected and ln.rstrip("\n") == "discogs:":
        out.append(f"  user_token: {token}\n")
        injected = True
if not injected:
    out.append("discogs:\n")
    out.append(f"  user_token: {token}\n")

# --- the destination side of the token channel (CR-03) -------------------------------------
# This used to be `open(dest, "w")` followed by `os.chmod(dest, 0o600)`, and BOTH halves of
# that were wrong:
#
#   * `umask 077` governs the mode of a NEWLY CREATED file only; it has no effect on one that
#     already exists. A $DEST left at 0644 by a prior run, a `cp`, or an editor backup was
#     TRUNCATED AND KEPT ITS MODE, so the live 40-character token landed world-readable on a
#     host running 100+ containers, and stayed that way until the chmod returned.
#   * If the write raised - ENOSPC on the ext4 root that plan 03-03 finding 4 warns about -
#     `os.chmod` never ran at all, and a partial, world-readable, token-bearing file was left
#     on disk permanently. There was no try/finally and no trap.
#
# So the mode is correct BEFORE the first token byte is written, on every path:
#   1. O_CREAT|O_EXCL creates a NEW file with mode 0600. O_EXCL means it can never inherit an
#      existing file's mode, and never truncates something already there.
#   2. os.fchmod pins 0600 explicitly rather than trusting the umask to have been 077.
#   3. The token is written into that already-0600 file, fsync'd, then os.replace()d over the
#      destination. os.replace is atomic within a filesystem and carries the mode with it, so
#      there is no instant at which $DEST is both token-bearing and world-readable.
#   4. Every failure path unlinks the partial file - which was 0600 for its whole lifetime.
#
# The staging file is created in the SAME DIRECTORY as $DEST, never in the system temp
# directory: on LXC 100 that is tmpfs backed by host RAM (T-01-15), and a credential does not
# belong in a world-shared directory either.
dest_dir = os.path.dirname(os.path.abspath(dest)) or "."
tmp = os.path.join(dest_dir, f".{os.path.basename(dest)}.{os.getpid()}.partial")

fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
try:
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fd = None  # fdopen owns the descriptor now
        fh.write("".join(out))
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(tmp, dest)
except BaseException:
    if fd is not None:
        os.close(fd)
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise

# Assert rather than report - README / CLAUDE.md § Health Checks. A printed mode that nothing
# checks is how the original defect read as correct.
mode = os.stat(dest).st_mode & 0o777
if mode != 0o600:
    raise SystemExit(
        f"REFUSING: {dest} is mode {oct(mode)} after the write, expected 0o600. "
        "It carries a live Discogs token - remove it."
    )
print(f"wrote {dest} mode {oct(mode)} ({len(out)} lines, token injected={injected})")
PY
