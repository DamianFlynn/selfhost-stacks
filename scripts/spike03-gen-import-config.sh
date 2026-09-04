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
BASE="$BASE" DEST="$DEST" python3 - <<'PY'
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
