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
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — A SECOND FATAL BLOCK WAS ADDED 2026-09-01 (plan 02-09,
#     D-41).
#     (Retitled 2026-09-03 by plan 02.1-10. Only the first six words are new: this notice was
#     written as "A SECOND FATAL BLOCK WAS ADDED" and did not carry the shared phrase, so
#     `grep -c 'EXIT-CODE BEHAVIOUR CHANGED'` returned 1 while the file held two such notices.
#     The convention is now greppable, which is the only reason to name a thing consistently.)
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
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — A THIRD FATAL BLOCK WAS ADDED 2026-09-03 (phase 02.1,
#     plan 02.1-10, D-20).
#     scripts/check-jellyfin-transcode.sh now also runs here, and it too exits this script 1.
#     Stated in the file for the same reason as the two notices above: a silent addition to what
#     can fail a shared health check is exactly the kind of thing that should be visible here and
#     not only in a plan.
#
#     (The plan set was written 2026-09-02 and its acceptance criterion names that date. Execution
#     crossed midnight UTC, so the true addition date is the 3rd and that is what is recorded —
#     the same UTC/local rollover that cost plan 02.1-06 a run when its proof client computed a
#     log filename by date arithmetic. A notice that states when it was added should state when it
#     was actually added.)
#
#     WHAT MAKES IT EXIT 1 — seven conditions, and six of them are "could not look":
#       - a failed assertion in the check itself
#       - LXC 100 (172.16.1.159) unreachable            [caught by the probe at lines 60-69]
#       - atlantis (172.16.1.158) unreachable, so the authoritative zfs quota and mounted
#         readings cannot be taken
#       - the Jellyfin container absent or docker unavailable
#       - the credential file at /mnt/fast/secrets/jellyfin-deercrest.env absent, or not 600 root
#       - fast/transcode UNMOUNTED. This one is the least obvious and the most dangerous: if the
#         dataset is not mounted, /mnt/fast/transcode is a PLAIN DIRECTORY on the parent, the bind
#         still works, the container still writes — and the 50 G quota applies to none of it,
#         while `zfs get quota` from atlantis still returns 53687091200 and reads perfectly green.
#         An unmounted dataset is an unbounded transcode path that looks completely normal.
#       - SEVENTH CONDITION, added 2026-09-03 by plan 02.1-13: a remote command exceeding
#         REMOTE_TIMEOUT. This is not a fourth fatal block — nothing new was folded in. It bounds
#         an existing coupling: until now NO remote command here had a wall-clock bound at all, so
#         a wedged dockerd made this script hang forever rather than fail. A check that never
#         RETURNS is worse than one that returns wrong, because there is not even a transcript to
#         disbelieve — and the assertions plan 02.1-11 added above are worth exactly what this
#         script's ability to return is worth. See the REMOTE_TIMEOUT block below for why the
#         bound is applied on the far side of the ssh rather than around it.
#
#     WHAT IT COVERS, by requirement id:
#       TRAN-01  the mount shape — /cache and /cache/transcodes are declared binds to /mnt/fast
#       TRAN-02  ZERO `Type: volume` mounts on the container. The INVARIANT, not one volume id:
#                a fresh anonymous volume with a different id is the same failure
#       TRAN-03  the 50 G ZFS quota on fast/transcode AND the dataset being mounted
#       TRAN-04  the five encoding values, ASSERTED against named expectations, plus the two
#                amdgpu values, REPORTED (D-30)
#       TRAN-05  `/` headroom against a 20 GiB floor
#
#     WHICH OF ITS ROWS ARE REPORTED, NOT ASSERTED — so the reader knows it will not go
#     permanently red, which is the 01-09 trap and the reason the mode-bit assertions were
#     removed from check-music-freeze.sh:
#       - The FIVE RETENTION VALUES ARE ASSERTED (TranscodingTempPath, EnableSegmentDeletion,
#         SegmentKeepSeconds, EnableThrottling, ThrottleDelaySeconds). Each is compared against a
#         named EXPECT_* expectation in check-jellyfin-transcode.sh and each increments FAILURES
#         on mismatch. This is DRIFT DETECTION and is explicitly NOT a claim that a setting
#         FIRES: a standing check cannot start a transcode. The firing proofs were executed once,
#         by plan 02.1-06, from Jellyfin's own Debug log — do not let this read-back stand in for
#         that (CONS-04). Corrected 2026-09-03 by plan 02.1-11: this block used to say all seven
#         values were reported and called them a regression detector, which is what they were
#         MEANT to be and not what the code did — FAILURES never incremented on drift, and this
#         file's own selector did not display them on the green path either (CR-01).
#       - The TWO AMDGPU VALUES (HardwareAccelerationType, EnableHardwareEncoding) remain
#         REPORTED, deliberately. D-30's contract is that 02.1-05's write PRESERVED them, which
#         02.1-05 asserted at write time and disable-jellyfin-hwaccel.sh's verify-retention
#         re-asserts on the recovery path; promoting them to a third assertion class is a
#         separate decision with its own controls. Not an oversight.
#       - The `/` headroom floor is GREEN TODAY WITH MEASURED MARGIN, chosen that way
#         deliberately. At the phase head the margin was 185 MiB; after 02.1-06 deleted the
#         12.55 GiB anonymous volume and 02.1-09 reaped four images it is 14.48 GiB. A
#         permanently-red check trains the reader to ignore it, so a red here should be read as
#         real.
#       - Section 4's `df` reading of the transcode directory is REPORTED (corroboration only).
#       - AND THE PERMANENTLY-RED TRAP NOW HAS A CONCRETE ANSWER, which is why promoting five
#         rows to assertions does not re-open it. Every expectation is a named ${VAR:-default}
#         constant in ONE block at the top of check-jellyfin-transcode.sh. A deliberate policy
#         change is a one-line edit there, made in the same commit as the change, and a red names
#         the exact line to edit. The 01-09 failure was an assertion with nowhere to go once the
#         estate legitimately moved; this one always has somewhere to go.
#
#     A JELLYFIN API BLIP IS NOT A BOUND VIOLATION. The encoding GET retries 3× at 2 s and, if
#     all three fail, is reported as `UNREACHABLE` in a counter kept SEPARATE from the failure
#     count. The script still exits non-zero — fail-closed is not negotiable (D-19) — but the
#     reader can tell "could not look" from "the value moved". A check that goes red for
#     transient reasons trains the reader to ignore it exactly as a permanently-red one does.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — NO NEW BLOCK, A NEW FATAL CONDITION AT AN EXISTING SITE,
#     2026-09-03 (plan 02.1-15, CR-03).
#     The shared opening phrase is kept literal on purpose — it is the greppable convention plan
#     02.1-10 established, and it must keep counting every such notice. (The grep over-counts by
#     one: the notice at the top of this file quotes the phrase inside its own body. Left alone
#     rather than "fixed", because rewording a notice to flatter a grep is the wrong direction.)
#     Nothing was folded in here — no fourth script runs.
#
#     WHAT CHANGED: the CONTAINER COUNT (`docker ps -q`) was reported-only. A wedged dockerd made
#     it print `Containers running: 0` and the script could still exit 0. It now exits 1 when that
#     count cannot be taken. The UNHEALTHY count was already fatal on UNKNOWN in principle, but
#     its guard could not fire for the case its own comment named — so in practice a wedged
#     dockerd printed `✅ No unhealthy containers` and exited 0 there too. Both now exit 1.
#
#     WHY IT IS WORTH A NOTICE RATHER THAN A QUIET FIX: the change makes this script red on a
#     failure mode that used to read green, so anything that treats a non-zero exit as an alarm
#     will see something it has never seen. That is the intent — the seventh condition listed
#     above ("a remote command exceeding REMOTE_TIMEOUT") was declared by plan 02.1-13 and, at
#     these two sites, was NOT ACTUALLY DELIVERED. This notice records that the declaration and
#     the code have been reconciled, not that a new class of failure was invented.
#
# ⚠️  KNOWN LIMIT, AND IT APPLIES TO THIS WHOLE FILE: THIS SCRIPT IS MANUAL. IT ONLY EVER FIRES
#     WHEN SOMEBODY TYPES IT (D-22, phase 02.1).
#     There is no cron entry, no systemd timer and no notification path. Nothing here will tell
#     you anything at 3am. If you are reading a green tick from this script, it is green because
#     you asked — not because anything has been watching.
#
#     That matters more than it sounds, because of what this file now covers. The incident phase
#     02.1 exists to fix was 19 GB accumulating in an anonymous Docker volume on / over roughly
#     36 hours, taking / to zero, with NOBODY LOOKING. The block above closes the "we had no way
#     to see it" half of that. It does not close the "nobody looked" half, and this notice exists
#     so a reader does not mistake the first for the second.
#
#     Scheduling and alerting are DELIBERATELY DEFERRED, not overlooked. Delivery, deduplication
#     and notification-channel choice are their own decisions with their own failure modes — and
#     the specific reason for the deferral is that PHASE 2 CLOSED WITH A MOUNT-FAILURE
#     NOTIFICATION THAT WAS NEVER PROVEN TO DELIVER. An unproven notification path is WORSE than
#     a known-manual check, because it feels covered. A known limit you can read is safer than an
#     assumed capability you cannot test.
#
#     So: run this after any change to Jellyfin, the fast/* datasets, the NFS export or the
#     Music library, and on any morning the estate feels odd. Recorded here rather than only in
#     a planning document because the person about to trust a green tick is the person who needs
#     to know it only ran because they typed it.

EXIT_CODE=0

# WR-10: ONE REACHABILITY PROBE, GATING THE WHOLE FILE.
#
# Everything below reads container state over ssh from 172.16.1.159. The five legacy blocks
# degrade badly when that host is down, and they do it in the two worst ways at once:
#
#   * UNHEALTHY=$(ssh ... | wc -l) comes back EMPTY, `[ "" -gt 0 ]` writes "integer expression
#     expected" to stderr and returns 2, and the else branch prints "✅ No unhealthy containers".
#   * the Traefik and Authelia blocks read ssh's exit 255 as "the container is not running" and
#     print "❌ Not running" - a confident and WRONG diagnosis rather than UNKNOWN.
#
# That directly contradicts the doctrine stated 60 lines further down in this same file ("Absence
# of a failure signal is NOT evidence of health"), which the two music blocks do honour. Before
# this gate, an LXC 100 outage produced a transcript reading "❌ Not running / ❌ Not running /
# Containers running: <blank> / ✅ No unhealthy containers" - the exit code saved it, the
# transcript above it was misinformation.
#
# Probing once and refusing is better than hardening five call sites: it makes the unreachable
# case a single, unmissable statement instead of five separately-wrong lines.
SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=10"

# WR-08: A WALL-CLOCK BOUND ON EVERY REMOTE COMMAND, ENFORCED ON THE FAR SIDE OF THE ssh.
#
# Three things a reader would otherwise get wrong, in the order they get them wrong:
#
#   1. ConnectTimeout BOUNDS THE CONNECT AND NOTHING AFTER IT. SSH_OPTS above carries
#      ConnectTimeout=10, which is easy to mistake for a bound on the whole call. It is not. A
#      wedged dockerd ACCEPTS THE CONNECTION INSTANTLY and then never returns — the estate's own
#      2026-08-31 amdgpu signature, where dockerd blocked reading /proc/*/smaps behind a dead
#      mmap_lock and every `docker` call stopped returning. Before this bound, this script would
#      have sat there indefinitely: no tick, no red, no exit.
#
#   2. ServerAliveInterval / ServerAliveCountMax DO NOT HELP EITHER, and reaching for them is the
#      obvious wrong fix. sshd is alive and answers keepalives perfectly happily while the command
#      it spawned is blocked. THE TRANSPORT IS HEALTHY; THE COMMAND IS NOT. Keepalives measure the
#      wrong thing, and would have kept this script alive rather than ended it.
#
#   3. SO THE BOUND GOES ON THE REMOTE SIDE, INSIDE THE COMMAND STRING — and that asymmetry with
#      the rest of the repo is deliberate, not an oversight to be "tidied" later.
#      scripts/disable-jellyfin-hwaccel.sh:172 wraps its own ssh calls as `timeout 15 ssh ...`
#      because THAT SCRIPT RUNS ON LINUX and can bound locally. THIS script runs on the macOS
#      workstation, which does not ship coreutils `timeout` at all (Homebrew's coreutils provides
#      it as `gtimeout`), so a workstation-side wrapper would be an undeclared dependency that
#      fails on the one machine this file is meant to be typed on. LXC 100 is Linux and has it,
#      so the bound executes there. Probed once, below — never provided, never assumed.
#
#   4. AND THE BOUND DOES NOT BIND THROUGH A PIPE ON ITS OWN. Added 2026-09-03 by plan 02.1-15
#      (CR-03), because points 1-3 were written on 2026-09-03 by plan 02.1-13 and left this
#      unsaid, and two call sites were silently defeated by it. `timeout T cmd | wc -l` signals
#      only `cmd`; `wc` then reports success over the empty stream and the pipeline exits 0. Any
#      remote command string in this file that contains a `|` therefore needs BOTH `set -o
#      pipefail` at the front of that string AND the ssh status captured and branched on — see
#      the long note at the container-count site for why neither half suffices alone. This is
#      the greppable rule: `grep -n 'timeout \$REMOTE_TIMEOUT.*|' ` over this file should return
#      only lines whose command string also contains `pipefail`, or lines whose final stage is a
#      `grep -q` that already exits non-zero on an empty stream (documented at those sites).
#
# WHY 120 s: this script's slowest fold-in retries a Jellyfin GET 3x at 2 s apart with
# --max-time 20, so a HEALTHY worst case is comfortably under a minute. 120 s is generous enough
# that a slow-but-working estate is never cut off (the 01-09 trap: a check that goes red for
# non-reasons trains the reader to ignore it), and short enough that a wedged dockerd is caught in
# the same sitting. Overridable so the bound can be exercised without editing this file, which is
# how plan 02.1-13 drove it against a real sleeping remote script.
REMOTE_TIMEOUT="${REMOTE_TIMEOUT:-120}"

# WR-01: THE TWO PROBES BELOW USED TO BE UNBOUNDED, ON A JUSTIFICATION THAT WAS FALSE.
# Corrected 2026-09-03 by plan 02.1-15. The withdrawn claim was that the only way these two can
# fail to return is a dead transport, and that the ConnectTimeout set above therefore already
# covered it. IT DID NOT. (Paraphrased rather than quoted, same convention as the two other
# withdrawn claims in this file: a false statement left in-band verbatim is one that gets
# re-copied, and it is also one a mechanical grep can no longer prove absent.)
# ConnectTimeout bounds the TCP connect, and in some OpenSSH versions the banner exchange. It does
# NOT bound authentication, PAM, session setup, or the fork of the remote shell. A host that
# completes the handshake and then cannot fork — PID exhaustion, memory pressure, A FULL `/`,
# WHICH IS THE EXACT INCIDENT THIS PHASE EXISTS TO FIX — leaves both probes hanging forever.
#
# That mattered more than anywhere else in this file, because these two GATE EVERYTHING: a hang
# here is a hang of the whole check, with no transcript at all, which is the one failure mode
# plan 02.1-13 named as worse than a wrong answer. The bound it added stopped one line short of
# the two calls that could swallow it.
#
# WHY THE BOUND IS ON THIS SIDE HERE, WHEN POINT 3 ABOVE INSISTS IT GOES ON THE REMOTE SIDE.
# Not a contradiction — the two are bounding different things. The REMOTE_TIMEOUT sites are
# bounding a remote command that has already started; the bound can therefore live with it. These
# two are bounding the possibility that NO REMOTE COMMAND EVER STARTS. A remote-side `timeout`
# cannot bound its own failure to be forked, and the second probe exists precisely to find out
# whether that instrument is present, so using it here would be circular. The bound has to be
# local, and the workstation is macOS with no coreutils `timeout`, so it is written in bash.
#
# WHY NOT ServerAliveInterval/ServerAliveCountMax, which is the obvious reach. Point 2 above
# already rejects keepalives for the wedged-dockerd case, and the argument is at least as strong
# here: sshd answers keepalives from its own process, so whether they fire at all when a session
# fork is stuck depends on where inside sshd the block lands — which is precisely the thing that
# could not be driven safely on a live 103-container host. A bound whose behaviour depends on an
# untested internal is not a bound. The watchdog below bounds wall clock unconditionally, wherever
# the hang is, and its behaviour WAS driven — see below.
#
# WHAT IT DOES: backgrounds the ssh, backgrounds a killer, waits for whichever finishes first.
# Written for bash 3.2, because /bin/bash on macOS is 3.2.57 and that is what `#!/bin/bash` gets.
#
# THE SENTINEL IS NOT DECORATION. Driven measurement: when the watchdog TERMs it, ssh exits 255 —
# THE SAME 255 AN UNREACHABLE HOST GIVES. So the exit status alone CANNOT tell "the bound expired"
# from "the transport is dead", and this file's whole doctrine is that those two answers must not
# share a verdict. The sentinel file is written by the watchdog immediately before it kills, so
# its existence afterwards is proof the bound is what ended the call. Driven under bash 3.2.57:
#   ssh true                    -> rc=0   timed_out=0  0s
#   ssh 'exit 3'                -> rc=3   timed_out=0  0s   (a real answer is never masked)
#   ssh 'sleep 300', bound 6    -> rc=255 timed_out=1  6s
#   ssh 'sleep 300', bound 3    -> rc=255 timed_out=1  3s
#   ssh to a dead host          -> rc=255 timed_out=0  10s  (ConnectTimeout, well inside)
#
# KNOWN LIMIT, stated because it is real: this kills the ssh CLIENT, not the remote command. A
# remote `sleep` outlives it — confirmed by driving it. That is irrelevant for these two probes
# (`true` and `command -v` have either already finished or never started) but do not reach for
# this function to bound a remote command that has side effects; use REMOTE_TIMEOUT for those.
PROBE_TIMEOUT="${PROBE_TIMEOUT:-20}"   # generous: connect + auth + fork on a healthy host is <1 s
BOUNDED_SSH_TIMED_OUT=0
bounded_ssh() {
    local secs="$1"; shift
    local cmd_pid watch_pid rc sentinel
    BOUNDED_SSH_TIMED_OUT=0
    sentinel=$(mktemp -t qhc-bound 2>/dev/null) || sentinel="${TMPDIR:-/tmp}/qhc-bound.$$.$RANDOM"
    rm -f "$sentinel"
    "$@" </dev/null & cmd_pid=$!
    { sleep "$secs"; : > "$sentinel"; kill -TERM "$cmd_pid" 2>/dev/null; } & watch_pid=$!
    wait "$cmd_pid" 2>/dev/null; rc=$?
    kill -TERM "$watch_pid" 2>/dev/null
    wait "$watch_pid" 2>/dev/null
    [ -e "$sentinel" ] && BOUNDED_SSH_TIMED_OUT=1
    rm -f "$sentinel"
    return "$rc"
}

echo "=== Quick Server Health Check ==="

if ! bounded_ssh "$PROBE_TIMEOUT" ssh $SSH_OPTS root@172.16.1.159 true 2>/dev/null; then
    if [ "$BOUNDED_SSH_TIMED_OUT" -eq 1 ]; then
        echo "⚠️  UNKNOWN — the reachability probe to 172.16.1.159 (LXC 100) did not return within"
        echo "  ${PROBE_TIMEOUT}s and was killed. THIS IS NOT THE SAME AS UNREACHABLE: the host may"
        echo "  be answering TCP and authenticating fine while unable to fork a shell — PID"
        echo "  exhaustion, memory pressure, or a FULL / , which is this phase's own incident."
        echo "  Check from atlantis (172.16.1.158), which does not depend on this path:"
        echo "    ssh root@172.16.1.158 'pct exec 100 -- df -h /; pct exec 100 -- uptime'"
    else
        echo "⚠️  UNKNOWN — 172.16.1.159 (LXC 100) is unreachable over ssh."
        echo "  NO container state can be read, so nothing below would be a measurement."
        echo "  This is UNKNOWN, not healthy. Check the host, then re-run."
    fi
    exit 1
fi

# Second one-shot probe, same argument as the WR-10 gate above: probe once and refuse, rather than
# harden ten call sites. Every remote command below is bounded by coreutils `timeout` ON LXC 100.
# If that binary is not there, the bounds are silently absent and a hang would once again be
# indistinguishable from a slow answer — so this refuses instead. It does NOT try to provide the
# binary: fetching software onto a host from inside a read-only health check is not this file's
# business, and a health check that mutates the thing it measures is not a health check.
if ! bounded_ssh "$PROBE_TIMEOUT" ssh $SSH_OPTS root@172.16.1.159 'command -v timeout >/dev/null 2>&1' 2>/dev/null; then
    if [ "$BOUNDED_SSH_TIMED_OUT" -eq 1 ]; then
        echo "⚠️  UNKNOWN — the \`timeout\` probe on 172.16.1.159 did not return within"
        echo "  ${PROBE_TIMEOUT}s and was killed. Note what this is NOT: it is not a finding that"
        echo "  coreutils is missing. It is a finding that the host would not answer, which is a"
        echo "  strictly worse state and is reported as its own thing. See the note above for how"
        echo "  to check it from atlantis rather than through this same path."
    else
        echo "⚠️  UNKNOWN — coreutils \`timeout\` is absent on 172.16.1.159 (LXC 100)."
        echo "  Every remote command below depends on it for its wall-clock bound, so with it missing"
        echo "  NO remote command can be bounded and a wedged dockerd would hang this script forever"
        echo "  instead of failing it. That is UNKNOWN, not healthy — and it is the one failure mode"
        echo "  that produces no transcript at all. Restore coreutils on the host, then re-run."
    fi
    EXIT_CODE=1
    exit 1
fi

# Check Traefik is running
#
# THE BOUND GOES INSIDE THE REMOTE COMMAND STRING, NOT BEFORE `ssh`. On a piped remote such as
# "docker ps ... | grep -q ..." the prefix binds to the FIRST command only — which is exactly the
# one that hangs, because `docker` is the client that talks to the wedged daemon while `grep` and
# `wc` are local to the remote shell and cannot block.
#
# ⚠️  THE SENTENCE THAT USED TO END THAT PARAGRAPH WAS WRONG AND IS WITHDRAWN (plan 02.1-15,
# CR-03). It said that binding the whole pipeline "would need a subshell and would buy nothing".
# It buys the difference between a bound that binds and a bound that does not: `wc -l` reports
# success over the stream left behind by the killed first stage, so the two container-count sites
# below returned 0 and printed a green tick on a wedged dockerd. It also does not need a subshell
# — `set -o pipefail` costs one statement. The claim is paraphrased rather than quoted so a
# mechanical grep for it over this repo keeps returning zero; a false claim left in-band verbatim
# is one that gets re-copied, which is precisely how it survived long enough to defeat CR-03.
#
# THE THREE SITES BELOW ARE DELIBERATELY LEFT AS THEY ARE, and the reason is specific to their
# last stage, not a blanket exemption. Traefik (`grep -q '^traefik$'`), Authelia (`grep -q
# '^authelia$'`) and the dashboard (a LOCAL `| grep -q "200"`) all end in a `grep -q`, which
# exits 1 on an empty stream. A killed first stage therefore lands in the `else` branch: they
# print "❌ Not running" / "❌ Not accessible". That is a CONFIDENT WRONG DIAGNOSIS and it is a
# real defect — it is filed as WR-02 and is NOT closed here — but it is not the CR-03 defect,
# because it is not a false green: the reader is shown a red, and no branch here reports health
# it did not measure. None of the three touches EXIT_CODE, which is why WR-02 is rated below
# CR-03 rather than alongside it. Fixing them means a `case` over the captured status at each
# site and changing what a genuinely-stopped container prints; that is its own change with its
# own control, and doing it half-way inside this one would be worse than leaving it legible.
echo -n "Traefik: "
if ssh $SSH_OPTS root@172.16.1.159 "timeout $REMOTE_TIMEOUT docker ps --format '{{.Names}}' | grep -q '^traefik$'"; then
    echo "✅ Running"
    # Check if it's healthy
    STATUS=$(ssh $SSH_OPTS root@172.16.1.159 "timeout $REMOTE_TIMEOUT docker inspect traefik --format='{{.State.Health.Status}}' 2>/dev/null || echo 'no healthcheck'")
    echo "  Health: $STATUS"
else
    echo "❌ Not running"
fi

# Check Authelia
echo -n "Authelia: "
if ssh $SSH_OPTS root@172.16.1.159 "timeout $REMOTE_TIMEOUT docker ps --format '{{.Names}}' | grep -q '^authelia$'"; then
    echo "✅ Running"
else
    echo "❌ Not running"
fi

# Count containers
#
# CR-03 — THE BOUND DID NOT BIND HERE, AND `wc -l` LAUNDERED THE KILL INTO A ZERO.
# Corrected 2026-09-03 by plan 02.1-15. Both count sites below carry the same two-part fix, and
# BOTH PARTS ARE NECESSARY — this is the one comment in this file worth reading before editing
# either of them, because each part alone leaves the defect standing:
#
#   1. `set -o pipefail` IN THE REMOTE COMMAND STRING. `timeout T docker ps -q | wc -l` signals
#      only the FIRST stage. `wc -l` then reads the empty stream, prints `0` and exits 0, and
#      without pipefail the remote pipeline's status IS `wc`'s — so ssh returned 0 and a killed
#      command was indistinguishable from a healthy answer. Driven on LXC 100:
#        timeout 2 sleep 20 | wc -l                    -> stdout 0, rc 0    (the bug)
#        set -o pipefail; timeout 2 sleep 20 | wc -l   -> stdout 0, rc 124  (the fix)
#      Safe to rely on: root's shell on LXC 100 is bash 5.2, and if it ever became a shell without
#      pipefail the `set` itself fails, ssh returns non-zero, and the UNKNOWN branch fires. It
#      fails closed either way.
#
#   2. CAPTURE ssh's STATUS, AND BRANCH ON 124. pipefail alone is NOT enough, because `wc -l`
#      still PRINTS `0` on the killed path — see the driven line above, where stdout is `0` in
#      both the broken and the fixed case. The value is unusable; only the status carries the
#      truth. Hence the report moved inside an explicit branch.
#
# THE STATUS MUST BE READ WITH NO LOCAL PIPE IN FRONT OF IT. `VAR=$(ssh ... | tr -d ' ')` makes
# `$?` the TR's status, and `${PIPESTATUS[0]}` DOES NOT RESCUE IT — an assignment is a SIMPLE
# COMMAND, not a pipeline, so bash sets PIPESTATUS to a single element holding the assignment's
# own status. Measured, not assumed: that shape reports `PIPESTATUS[0]=0, PIPESTATUS[1]=unset`
# while the remote really did exit 124. So the whitespace strip happens on its own line, AFTER
# the status has been taken. Do not fold it back into the assignment.
#
# WHY THIS NOW SETS EXIT_CODE. A kill here used to print `Containers running: 0` and carry on:
# reported-only, so a wedged dockerd left the script free to exit 0. "Could not look", "there are
# none" and "BROKEN" are three different answers and this file's whole doctrine is that they must
# not share a verdict. They are now three branches.
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

# Check for unhealthy. The gate above guarantees the host answered, but dockerd can still be
# wedged behind the amdgpu mmap_lock while sshd is fine (that is exactly the Aug 31 signature),
# so a non-numeric result here is still UNKNOWN rather than zero.
#
# CR-03 AGAIN, AND THIS IS THE SITE THAT MATTERED. The `! grep -qE '^[0-9]+$'` guard below carried
# the sentence above it and could never fire for the case that sentence names: `wc -l` ALWAYS
# emits a number, so the pattern always matched, and the only way to reach the guard was ssh
# transport failure — which the probe further up already exits on. A wedged dockerd printed
# `✅ No unhealthy containers` and left EXIT_CODE at 0: a green tick, on a host nobody had looked
# at, produced by the single failure mode this phase exists to eliminate. The guard is kept (it
# is still the right catch for a malformed answer) but it is no longer the only one, and it is no
# longer the FIRST one — 124 is now split out ahead of it. See the two-part note above.
UNHEALTHY=$(ssh -n $SSH_OPTS root@172.16.1.159 "set -o pipefail; timeout $REMOTE_TIMEOUT docker ps --format '{{.Names}}' --filter health=unhealthy | wc -l")
UNHEALTHY_RC=$?   # ssh propagates the remote status — NO local pipe above, see the note above
UNHEALTHY=$(printf '%s' "$UNHEALTHY" | tr -d '[:space:]')
if [ "$UNHEALTHY_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — the unhealthy-container query exceeded its ${REMOTE_TIMEOUT}s bound and"
    echo "  was killed. Nothing was counted. This is NOT 'no unhealthy containers'."
    echo "  Most likely cause: dockerd wedged. Distinguish it on atlantis (172.16.1.158) with"
    echo "  /proc/pressure/io 'full' near 100% WITH AN IDLE CPU; a busy CPU is not the wedge."
    EXIT_CODE=1
elif [ "$UNHEALTHY_RC" -ne 0 ] || ! echo "$UNHEALTHY" | grep -qE '^[0-9]+$'; then
    echo "⚠️  UNKNOWN — could not count unhealthy containers (ssh exit $UNHEALTHY_RC, docker"
    echo "  returned '$UNHEALTHY'). dockerd may be blocked. This is NOT 'no unhealthy containers'."
    EXIT_CODE=1
elif [ "$UNHEALTHY" -gt 0 ]; then
    echo "⚠️  Unhealthy containers: $UNHEALTHY"
    ssh -n $SSH_OPTS root@172.16.1.159 "timeout $REMOTE_TIMEOUT docker ps --format '{{.Names}}' --filter health=unhealthy"
else
    echo "✅ No unhealthy containers"
fi

# Try to curl Traefik dashboard
echo -n "Traefik dashboard: "
if ssh $SSH_OPTS root@172.16.1.159 "timeout $REMOTE_TIMEOUT curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/dashboard/" | grep -q "200"; then
    echo "✅ Accessible (HTTP 200)"
else
    echo "❌ Not accessible"
fi

# Music freeze harness (D-29). The audit is host-resident by design — stat over the library, a
# find across 2,674 entries and the docker mount enumeration are not one-liners — so it runs over
# a single ssh here. See scripts/check-music-freeze.sh for what it asserts.
#
# IN-05: `-n` on the ssh. check-music-consumers.sh (grep for "so a nested ssh cannot eat" — one
# hit, on the SSH_OPTS line) established this as a convention with a
# measured reason ("so a nested ssh cannot eat this script's stdin" - it does). Both remote
# invocations here are inline `ssh host 'cmd'`, which is the shape the convention covers; the
# shape it must be kept AWAY from is `bash -s` + heredoc, and neither of these is that. No current
# consequence, but without it the first ssh can drain this script's stdin if it is ever run with
# input attached, leaving the second with nothing.
echo -n "Music freeze harness: "
MUSIC_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 \
    "timeout $REMOTE_TIMEOUT bash /mnt/fast/stacks/scripts/check-music-freeze.sh 2>&1")
MUSIC_RC=$?   # ssh propagates the remote exit status — do NOT pipe before capturing this
# Strip ANSI colour separately. \x1b is a GNU sed extension and this script runs on macOS, so the
# ESC is spelled with bash's $'...' quoting instead.
MUSIC_OUT=$(printf '%s\n' "$MUSIC_OUT" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')

# THE EMPTY-OUTPUT TEST STAYS FIRST IN ALL THREE BLOCKS. Plan 02.1-10 proved by driving it
# (VALIDATION row 23) that a zero-byte remote script exits 0 with no output, so ONLY the
# empty-output test catches that case — an exit-status test never will. Adding the timeout branch
# below must not, and does not, move it.
#
# THE ONE QUALIFICATION, and it is the whole reason the timeout branch is reachable at all: a
# command killed by the bound usually produces NO OUTPUT EITHER, so on a real hang both this test
# and the timeout test are true at once. Unqualified, the empty test would win and print
# "unreachable" for a host that answered ssh perfectly — the exact "could not look" / "the value
# moved" conflation this file exists to avoid, just relocated. So the empty branch defers when the
# remote exit status was 124, and only then. A zero-byte script still exits 0 and still lands here.
if [ -z "$MUSIC_OUT" ] && [ "$MUSIC_RC" -ne 124 ]; then
    # Unreachable host, or the script is not on the host at all. Absence of a failure signal is
    # NOT evidence of health — same precedent as scripts/check-server-health.sh:8-11.
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the audit produced no output"
    echo "  The harness state is unknown, NOT green. Check the host, then re-run:"
    echo "  ssh root@172.16.1.159 'cd /mnt/fast/stacks && bash scripts/check-music-freeze.sh'"
    EXIT_CODE=1
elif [ "$MUSIC_RC" -eq 124 ]; then
    # coreutils `timeout` exits 124 on expiry. Without this branch that status would fall into the
    # generic "❌ BROKEN (... exit 124)" branch below — fail-closed, but SAYING THE WRONG THING. It
    # would read as "the check failed an assertion" when the truth is "the check never finished",
    # and those are different answers that must not share a verdict (the same doctrine as the
    # UNREACHABLE counter in check-jellyfin-transcode.sh, and as CR-02 in
    # disable-jellyfin-hwaccel.sh). Nothing was measured here; do not read it as a value moving.
    echo "⚠️  UNKNOWN — the remote audit exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  This is NOT a failed assertion. Nothing was measured — the command never returned."
    echo "  Most likely cause: dockerd wedged. The estate's 2026-08-31 amdgpu signature blocks"
    echo "  dockerd on /proc/*/smaps behind a dead mmap_lock while sshd answers normally, so the"
    echo "  connection succeeds and the command hangs. Distinguish it on atlantis (172.16.1.158):"
    echo "    /proc/pressure/io 'full' near 100% WITH AN IDLE CPU is the wedge; a busy CPU is not."
    echo "    cat /proc/pressure/io; uptime"
    echo "  A slow-but-healthy estate is the other possibility — re-run with a larger budget:"
    echo "    REMOTE_TIMEOUT=300 bash scripts/quick-health-check.sh"
    EXIT_CODE=1
elif [ "$MUSIC_RC" -eq 0 ]; then
    # WR-09: the ✅ used to be printed unconditionally and the evidence lines were best-effort.
    # If the anchor did not match, sed yielded nothing, grep exited 1, and this printed
    # "✅ Intact" with no supporting detail at all. check-music-freeze.sh treats that heading as
    # load-bearing and says so in capitals - a documented coupling with no detector is a coupling
    # that will break, and it would break on the branch that still prints a tick.
    SUMMARY=$(echo "$MUSIC_OUT" | sed -n '/^📊 7\. Summary/,$p' \
              | grep -E 'tagger-class|unclassified|declared rw|ownership mismatches')
    if [ -z "$SUMMARY" ]; then
        echo "⚠️  UNKNOWN — the harness exited 0 but its '📊 7. Summary' block was not found."
        echo "  The section heading this fold-in anchors on has changed, so nothing here was"
        echo "  actually read. State is UNKNOWN, not green. See check-music-freeze.sh's summary."
        EXIT_CODE=1
    else
        echo "✅ Intact"
        echo "$SUMMARY" | sed 's/^/  /'
    fi
else
    echo "❌ BROKEN (check-music-freeze.sh exit $MUSIC_RC)"
    echo "  Failed assertions:"
    echo "$MUSIC_OUT" | grep '❌' | sed 's/^ */    /'
    echo "  Summary:"
    echo "$MUSIC_OUT" | sed -n '/^📊 7\. Summary/,$p' | sed 's/^/  /'
    EXIT_CODE=1
fi

# Music consumers audit (D-41). Host-resident on LXC 100 for CREDENTIALS, not for command length:
# both the Music Assistant and Jellyfin credentials live at /mnt/fast/secrets/ there. See the
# `# Where it runs:` header of scripts/check-music-consumers.sh. It lands on the host by
# `git pull` into /mnt/fast/stacks — there is no copy step to remember.
# This block used to give reachability as a second reason, citing a claim measured false on
# 2026-09-03; see the REACHABILITY note on the transcode block below, which points at the single
# canonical statement in scripts/check-jellyfin-transcode.sh.
echo -n "Music consumers audit: "
CONSUMERS_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 \
    "timeout $REMOTE_TIMEOUT bash /mnt/fast/stacks/scripts/check-music-consumers.sh 2>&1")
CONSUMERS_RC=$?   # ssh propagates the remote exit status — do NOT pipe before capturing this
# Strip ANSI colour separately. \x1b is a GNU sed extension and this script runs on macOS, so the
# ESC is spelled with bash's $'...' quoting instead.
CONSUMERS_OUT=$(printf '%s\n' "$CONSUMERS_OUT" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')

# Empty-output test first, deferring only to the bound — see the full argument on the freeze block
# above. The ordering and the one qualification are identical in all three blocks on purpose.
if [ -z "$CONSUMERS_OUT" ] && [ "$CONSUMERS_RC" -ne 124 ]; then
    # Unreachable host, or the script is not on the host at all. Absence of a failure signal is
    # NOT evidence of health — same precedent as the freeze block above.
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the audit produced no output"
    echo "  The consumers state is unknown, NOT green. Check the host, then re-run:"
    echo "  ssh root@172.16.1.159 'cd /mnt/fast/stacks && git pull --ff-only && bash scripts/check-music-consumers.sh'"
    EXIT_CODE=1
elif [ "$CONSUMERS_RC" -eq 124 ]; then
    # `timeout` expiry, not a failed assertion. See the freeze block above for why these two are
    # kept apart. This block is the one most likely to bound out on a HEALTHY estate: it queries
    # Music Assistant and Jellyfin over HTTP, so a slow or restarting MA is a real possibility
    # here in a way it is not for a `docker ps`.
    echo "⚠️  UNKNOWN — the remote audit exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  This is NOT a failed assertion. Nothing was measured — the command never returned."
    echo "  Either dockerd is wedged (2026-08-31 amdgpu signature: /proc/pressure/io 'full' near"
    echo "  100% with an IDLE CPU, read on atlantis 172.16.1.158), or Music Assistant is slow to"
    echo "  answer. Re-run with a larger budget before concluding anything:"
    echo "    REMOTE_TIMEOUT=300 bash scripts/quick-health-check.sh"
    EXIT_CODE=1
elif [ "$CONSUMERS_RC" -eq 0 ]; then
    # WR-09, same defect as the freeze block above. check-music-consumers.sh says
    # "KEEP THIS HEADING LITERAL AND NEVER RENUMBER IT SILENTLY. Plan 02-09's fold-in anchors on
    # it" — grep that file for KEEP THIS HEADING LITERAL, one hit. (This pointer cited lines
    # 853-855; the text is at 1119. It was stale BEFORE this phase, not broken by it, and is
    # re-pointed here by plan 02.1-15 in the same pass as the four this phase did break.)
    # Until that guard existed nothing detected a break. Renumbering (a section 3b, splitting section
    # 4) moves the `6.` and the anchor fails on the branch that prints a tick.
    SUMMARY=$(echo "$CONSUMERS_OUT" | sed -n '/^📊 6\. Summary/,$p' \
              | grep -E 'MA version|albums matched in MA|albums matched in Jellyfin|FAILURES total')
    if [ -z "$SUMMARY" ]; then
        echo "⚠️  UNKNOWN — the audit exited 0 but its '📊 6. Summary' block was not found."
        echo "  The section heading this fold-in anchors on has changed, so nothing here was"
        echo "  actually read. State is UNKNOWN, not green. See check-music-consumers.sh's summary."
        EXIT_CODE=1
    else
        echo "✅ Both consumers see the library"
        echo "$SUMMARY" | sed 's/^/  /'
    fi
else
    echo "❌ BROKEN (check-music-consumers.sh exit $CONSUMERS_RC)"
    echo "  Failed assertions:"
    echo "$CONSUMERS_OUT" | grep '❌' | sed 's/^ */    /'
    echo "  Summary:"
    echo "$CONSUMERS_OUT" | sed -n '/^📊 6\. Summary/,$p' | sed 's/^/  /'
    EXIT_CODE=1
fi

# Jellyfin transcode retention audit (D-20). Host-resident on LXC 100 because it CANNOT run here:
# it measures free space with `df -B1 --output=avail`, which is GNU coreutils only. BSD df on macOS
# silently ignores --output and prints its own layout, which would parse into a WRONG NUMBER rather
# than into an error — so the script guards on `uname -s` and exits 2 on Darwin. Its API key also
# lives at /mnt/fast/secrets/ on that host and nowhere else. It lands on the host by `git pull`
# into /mnt/fast/stacks — there is no copy step to remember.
#
# REACHABILITY — CORRECTED 2026-09-03 (plan 02.1-12, CR-02), AND IT IS NOT A REASON THIS RUNS
# THERE. Both this block and the consumers block above used to give reachability as a reason,
# asserting that Jellyfin exposed no port on any host interface and could be reached from LXC 100
# alone. (Paraphrased, not quoted, so a mechanical grep for the withdrawn sentence over this repo
# keeps returning zero — a false claim left in-band verbatim is one that gets re-copied.)
# Measured false from three vantage points: Jellyfin
# answers 200 at 172.16.1.76:8096 — its iot_macvlan LAN address — from this very workstation and
# from atlantis, so an administrator-equivalent API surface is reachable across 172.16.1.0/24 and,
# via the estate's two subnet routers, from the tailnet. The exposure is SOLELY that macvlan
# address: the `ports:` list in jellyfin.yaml is inert (zero listeners on LXC 100, docker reports
# every port null, 172.16.1.159:8096 refuses from everywhere). What IS true is the converse and
# narrower fact: 172.16.1.76 is unreachable FROM LXC 100 under macvlan host isolation, which is
# why the host-side script resolves Jellyfin via `docker inspect` and uses t3_proxy.
# Stated in full ONCE, in the `# Where it runs:` header of scripts/check-jellyfin-transcode.sh,
# against the measurement at artifacts/02.1-12-reachability-measurement.txt. A fact stated twice
# is a fact that gets corrected once — which is how the old claim survived in three places.
#
# This is the block that would have caught the incident phase 02.1 exists to fix: 19 GB of
# transcode cache accumulated in an ANONYMOUS docker volume on / over ~36 hours, taking / to zero,
# with nothing anywhere saying so.
echo -n "Jellyfin transcode retention: "
TRANSCODE_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 \
    "timeout $REMOTE_TIMEOUT bash /mnt/fast/stacks/scripts/check-jellyfin-transcode.sh 2>&1")
TRANSCODE_RC=$?   # ssh propagates the remote exit status — do NOT pipe before capturing this
# Strip ANSI colour separately. \x1b is a GNU sed extension and this script runs on macOS, so the
# ESC is spelled with bash's $'...' quoting instead.
TRANSCODE_OUT=$(printf '%s\n' "$TRANSCODE_OUT" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')

# Empty-output test first, deferring only to the bound — see the full argument on the freeze block
# above. The ordering and the one qualification are identical in all three blocks on purpose.
if [ -z "$TRANSCODE_OUT" ] && [ "$TRANSCODE_RC" -ne 124 ]; then
    # Unreachable host, or the script is not on the host at all. Absence of a failure signal is
    # NOT evidence of health — same precedent as the two blocks above. PROVEN REACHABLE, not
    # assumed: plan 02.1-10 drove this branch by moving the host-side script aside (VALIDATION
    # row 23) and confirmed it exits this script 1, then restored it and re-verified by sha256.
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the audit produced no output"
    echo "  The transcode retention state is unknown, NOT green. Check the host, then re-run:"
    echo "  ssh root@172.16.1.159 'cd /mnt/fast/stacks && git pull --ff-only && bash scripts/check-jellyfin-transcode.sh'"
    EXIT_CODE=1
elif [ "$TRANSCODE_RC" -eq 124 ]; then
    # `timeout` expiry, not a failed assertion. PROVEN REACHABLE, not assumed: plan 02.1-13 drove
    # this exact branch by replacing the host-side check with a `sleep 30` stub and running at
    # REMOTE_TIMEOUT=5, then restored the real script under a trap and re-verified by sha256 —
    # the same device 02.1-10 used for the empty-output branch above. Transcript at
    # .planning/phases/02.1-.../artifacts/02.1-13-timeout-control.txt.
    #
    # This branch matters more here than in the two blocks above, because THIS is the block that
    # would have caught the incident phase 02.1 exists to fix. A hang here means the transcode
    # retention state was never read at all — which is the same standing as an unbounded transcode
    # path, not a lesser one.
    echo "⚠️  UNKNOWN — the remote audit exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  This is NOT a failed assertion, and it is NOT a bound violation. Nothing was measured:"
    echo "  the command never returned, so the transcode retention state is unread, not green."
    echo "  Most likely cause: dockerd wedged. The estate's 2026-08-31 amdgpu signature blocks"
    echo "  dockerd on /proc/*/smaps behind a dead mmap_lock while sshd answers normally, so the"
    echo "  connection succeeds and the command hangs. Distinguish it on atlantis (172.16.1.158):"
    echo "    /proc/pressure/io 'full' near 100% WITH AN IDLE CPU is the wedge; a busy CPU is not."
    echo "    cat /proc/pressure/io; uptime"
    echo "  A slow-but-healthy estate is the other possibility — re-run with a larger budget:"
    echo "    REMOTE_TIMEOUT=300 bash scripts/quick-health-check.sh"
    EXIT_CODE=1
elif [ "$TRANSCODE_RC" -eq 0 ]; then
    # WR-09, the same defect as both blocks above, and this is the THIRD fold-in to carry the
    # guard. check-jellyfin-transcode.sh says "KEEP THIS HEADING LITERAL AND NEVER RENUMBER
    # IT SILENTLY" — grep that file for KEEP THIS HEADING LITERAL, one hit. (This pointer cited
    # line 588 and was correct at 780ada8; plan 02.1-11 added ~157 lines above that heading and
    # moved it to 745, and nothing updated the pointer. Cited by anchor now — plan 02.1-15,
    # WR-09. The irony of a stale line number inside the comment that argues stale couplings
    # break silently is the reason every pointer in these three files is now an anchor.)
    # A documented coupling with no detector is a coupling that will break, and it
    # breaks on the branch that still prints a tick. PROVEN REACHABLE, not assumed: plan 02.1-10
    # renumbered that heading on purpose (VALIDATION row 24), confirmed this branch printed and
    # the exit was 1, then restored it and re-verified by sha256.
    # WHY `transcode target` IS IN THIS SELECTOR — it is the CR-01 fix, and it is the whole point.
    # The five encoding values were not only unasserted until 2026-09-03; this selector did not
    # match them either, so on the branch that PRINTS A TICK they were neither asserted nor
    # displayed. TranscodingTempPath is the one that makes that matter: drift it to Jellyfin's own
    # default /config/transcodes and the transcode cache moves off the quota'd dataset while the
    # binds, both mount instruments and the `/` floor all stay green. A drifted value has to be
    # legible HERE, on the green path, not only in the body of a script nobody opens on a good day.
    # `encoding values` and `toolchain missing` were both already named in the check's own
    # cross-file contract comment and had NEVER been selected — appended for the same reason.
    # The alternation below must equal the token set that check-jellyfin-transcode.sh's section 6
    # actually emits; a token that selects nothing looks exactly like a check with nothing to say.
    SUMMARY=$(echo "$TRANSCODE_OUT" | sed -n '/^📊 6\. Summary/,$p' \
              | grep -E '/ headroom|volume mounts|transcode quota|transcode mounted|unreachable|FAILURES total|transcode target|encoding values|toolchain missing')
    if [ -z "$SUMMARY" ]; then
        echo "⚠️  UNKNOWN — the audit exited 0 but its '📊 6. Summary' block was not found."
        echo "  The section heading this fold-in anchors on has changed, so nothing here was"
        echo "  actually read. State is UNKNOWN, not green. See check-jellyfin-transcode.sh's summary."
        EXIT_CODE=1
    else
        echo "✅ Transcode retention intact"
        echo "$SUMMARY" | sed 's/^/  /'
    fi
else
    echo "❌ BROKEN (check-jellyfin-transcode.sh exit $TRANSCODE_RC)"
    echo "  Failed assertions:"
    echo "$TRANSCODE_OUT" | grep '❌' | sed 's/^ */    /'
    echo "  Summary:"
    echo "$TRANSCODE_OUT" | sed -n '/^📊 6\. Summary/,$p' | sed 's/^/  /'
    EXIT_CODE=1
fi

if [ "$EXIT_CODE" -ne 0 ]; then
    echo ""
    # This line used to name only the three fold-in blocks. Plan 02.1-15 made the two container
    # counts able to set EXIT_CODE, and the driven control caught this immediately: the run failed
    # on the counts while all three fold-ins printed ✅, and the tail still sent the reader to the
    # three green ones. A pointer to the wrong place is the same class of defect as the stale
    # file:line references corrected in the same plan — it costs the reader the time the message
    # was written to save.
    echo "❌ Health check FAILED. The failing block is whichever one above carries a ❌ or a ⚠️ —"
    echo "   that is any of: the container counts, the music freeze harness, the consumers audit,"
    echo "   or the Jellyfin transcode retention audit."
    exit 1
fi
