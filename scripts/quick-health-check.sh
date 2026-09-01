#!/bin/bash
# Quick diagnostic to check Traefik, container health and the music-library freeze harness.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED 2026-08-18 (plan 01-09, D-29).
#     This script used to ALWAYS exit 0 — it printed ❌ for a down Traefik and carried on with no
#     other consequence. It now exits 1 when the music freeze harness fails or cannot be reached.
#     Stated here because other things may call this script and a silent-to-failing change is
#     exactly the kind of thing that should be visible in the file, not only in a plan.
#
#     Why: a check that is easy to ignore is a check that does not fire. The docker `created`-state
#     blind spot left dispatcharr and teleport down for six weeks while the estate reported clean.
#     The Traefik/Authelia blocks above are deliberately left as-is; only the harness is fatal,
#     because it is the only block here with a maintained assertion contract
#     (scripts/check-music-freeze.sh exits non-zero on any failed assertion).
#
#     The harness's two library mode counts are REPORTED, not asserted, so this script does not
#     inherit a permanent red — see MODE SCOPE in scripts/check-music-freeze.sh.
#
# ⚠️  A SECOND FATAL BLOCK WAS ADDED 2026-09-01 (plan 02-09, D-41).
#     scripts/check-music-consumers.sh now also runs here, and it too exits this script 1 on a
#     failed assertion or on an unreachable host. Stated in the file for the same reason as
#     above: a silent addition to what can fail a shared health check is exactly the kind of
#     thing that should be visible here and not only in a plan.
#
#     What it covers: CONS-01 (the ro NFS export of /mnt/tank/media/Music from atlantis to the
#     HA NUC), CONS-02 (three pinned proof albums exact-matched in Music Assistant on album name
#     AND album artist, attributed to the local filesystem provider) and CONS-03 (mount liveness).
#     It also reports the same three albums in Jellyfin.
#
#     Why it is load-bearing rather than nice-to-have: the Music Assistant add-on is on
#     auto_update (D-56), and MA is pinned to a BETA (2.11.0b0 at the time of writing). A release
#     that changes provider behaviour — the album-artist fallback, the provider filter, the API
#     shape — would otherwise land silently and the library would go wrong with nothing saying
#     so. This block IS the drift detector: the audit records the MA version every assertion was
#     proven at, so a behaviour change surfaces as a failed assertion rather than a silent pass.
#
#     Both its scope=temp-export rows and its Jellyfin out-of-scope rows are REPORTED, not
#     asserted, so this script does not inherit a permanent red from a torn-down control either.

EXIT_CODE=0

echo "=== Quick Server Health Check ==="

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

# Check Authelia
echo -n "Authelia: "
if ssh root@172.16.1.159 "docker ps --format '{{.Names}}' | grep -q '^authelia$'"; then
    echo "✅ Running"
else
    echo "❌ Not running"
fi

# Count containers
RUNNING=$(ssh root@172.16.1.159 "docker ps -q | wc -l" | tr -d ' ')
echo "Containers running: $RUNNING"

# Check for unhealthy
UNHEALTHY=$(ssh root@172.16.1.159 "docker ps --format '{{.Names}}' --filter health=unhealthy | wc -l" | tr -d ' ')
if [ "$UNHEALTHY" -gt 0 ]; then
    echo "⚠️  Unhealthy containers: $UNHEALTHY"
    ssh root@172.16.1.159 "docker ps --format '{{.Names}}' --filter health=unhealthy"
else
    echo "✅ No unhealthy containers"
fi

# Try to curl Traefik dashboard
echo -n "Traefik dashboard: "
if ssh root@172.16.1.159 "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/dashboard/" | grep -q "200"; then
    echo "✅ Accessible (HTTP 200)"
else
    echo "❌ Not accessible"
fi

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
    # Unreachable host, or the script is not on the host at all. Absence of a failure signal is
    # NOT evidence of health — same precedent as scripts/check-server-health.sh:8-11.
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

# Music consumers audit (D-41). Host-resident on LXC 100 for CREDENTIALS AND REACHABILITY, not
# for command length: Jellyfin publishes no host port and is reachable only from LXC 100, and
# both the Music Assistant and Jellyfin credentials live at /mnt/fast/secrets/ there. See the
# `# Where it runs:` header of scripts/check-music-consumers.sh. It lands on the host by
# `git pull` into /mnt/fast/stacks — there is no copy step to remember.
echo -n "Music consumers audit: "
CONSUMERS_OUT=$(ssh -o BatchMode=yes -o ConnectTimeout=10 root@172.16.1.159 \
    "bash /mnt/fast/stacks/scripts/check-music-consumers.sh 2>&1")
CONSUMERS_RC=$?   # ssh propagates the remote exit status — do NOT pipe before capturing this
# Strip ANSI colour separately. \x1b is a GNU sed extension and this script runs on macOS, so the
# ESC is spelled with bash's $'...' quoting instead.
CONSUMERS_OUT=$(printf '%s\n' "$CONSUMERS_OUT" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')

if [ -z "$CONSUMERS_OUT" ]; then
    # Unreachable host, or the script is not on the host at all. Absence of a failure signal is
    # NOT evidence of health — same precedent as the freeze block above.
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the audit produced no output"
    echo "  The consumers state is unknown, NOT green. Check the host, then re-run:"
    echo "  ssh root@172.16.1.159 'cd /mnt/fast/stacks && git pull --ff-only && bash scripts/check-music-consumers.sh'"
    EXIT_CODE=1
elif [ "$CONSUMERS_RC" -eq 0 ]; then
    echo "✅ Both consumers see the library"
    echo "$CONSUMERS_OUT" | sed -n '/^📊 6\. Summary/,$p' | grep -E 'MA version|albums matched in MA|albums matched in Jellyfin|FAILURES total' | sed 's/^/  /'
else
    echo "❌ BROKEN (check-music-consumers.sh exit $CONSUMERS_RC)"
    echo "  Failed assertions:"
    echo "$CONSUMERS_OUT" | grep '❌' | sed 's/^ */    /'
    echo "  Summary:"
    echo "$CONSUMERS_OUT" | sed -n '/^📊 6\. Summary/,$p' | sed 's/^/  /'
    EXIT_CODE=1
fi

if [ "$EXIT_CODE" -ne 0 ]; then
    echo ""
    echo "❌ Health check FAILED — see the music freeze harness and/or the consumers audit above."
    exit 1
fi
