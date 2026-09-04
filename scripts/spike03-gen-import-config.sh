#!/bin/bash
# Plan 03-07 (T-03-37): generate the `beet import -t` runtime config for the criterion-1
# cross-check.
#
# This is the ONLY file in Phase 3 that contains the Discogs token in plaintext. It lives
# outside the repository, is mode 600, and is deleted in plan 03-11.
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

with open(dest, "w", encoding="utf-8") as fh:
    fh.write("".join(out))
os.chmod(dest, 0o600)
print(f"wrote {dest} mode {oct(os.stat(dest).st_mode & 0o777)} "
      f"({len(out)} lines, token injected={injected})")
PY
