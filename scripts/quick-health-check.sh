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
#     THE SAME PRINCIPLE NOW COVERS THE PHASE 4 TAGGER CENSUS (2026-09-11, plan 04-06). The
#     harness gained a section 6b that asserts Phase 4's own outcome — one tagger definition, one
#     beets database, the retired tagger trees and databases gone, and no container in any state
#     holding rw on Music except Jellyfin.
#
#     CORRECTED 2026-09-14 (code review WR-05). This paragraph used to describe 6b as an opt-in
#     CANDIDATE, gated behind a caller-supplied environment variable, and told the reader that
#     nothing this script exits with would change until plan 04-11 promoted it. That stopped
#     being true on 2026-09-13. TAGGER_CENSUS_PROMOTED=1 (scripts/check-music-freeze.sh:144), 6b
#     RUNS ON EVERY ROUTINE INVOCATION, ITS ASSERTIONS ARE FATAL TO THIS SCRIPT, and its counters
#     ARE printed. The sixth notice below has said exactly that since the promotion, so this file
#     was carrying two notices that contradicted each other about the same block — and this was
#     the one a reader meets first. Paraphrased rather than quoted, the same convention as the
#     other withdrawn claims in this file: a false statement left in-band verbatim is one that
#     gets re-copied, and it is also one a mechanical grep can no longer prove absent.
#
#     The summary selector further down was widened for those census counters IN ADVANCE of the
#     promotion, which is why promoting was a one-file change. THOSE TOKENS ARE LIVE NOW. Read
#     the note at the selector itself before touching any of them.
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
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — PHASE 4: THE TAGGER CENSUS AND A FOURTH FATAL BLOCK (VENDORED-FILE DRIFT) WERE PROMOTED 2026-09-13 (plan 04-11, D-13/D-21/D-25)
#     Both had been running as CANDIDATES since waves 2 and 5 (see the two CANDIDATE -> PROMOTED
#     blocks below and in scripts/check-music-freeze.sh). They were promoted in the same commit as
#     the run that first turned them green, which is why this file has not carried a red at any
#     wave boundary. Measured immediately before the promotion: the census RC 0 in 4 s on LXC 100,
#     and this script RC 0 in 20 s with the drift block green.
#
#     WHAT NOW EXITS THIS SCRIPT 1 THAT DID NOT BEFORE — every one of these is new:
#       A. A CENSUS ASSERTION in scripts/check-music-freeze.sh section 6b, which is folded in
#          below and whose non-zero exit this script already propagates:
#            - tagger definitions != 1, or the one found is not
#              stacks/selfhosted/arrs/beets/beets.yaml
#            - beets databases != 1, or the one found is not SURVIVOR_DB
#              (/mnt/fast/appdata/arrs/beets/config/library.db)
#            - any wrtag/soulbeet tagger database present
#            - any retired tagger path present
#            - ANY container, in ANY state (created and exited included), holding a rw mount that
#              reaches /mnt/tank/media/Music — tagger-capable or not. Jellyfin is the single
#              documented D-21 consumer exception and is counted on its own line, so no total can
#              read as a pass for the wrong reason.
#       B. THE CENSUS BEING BLIND — "could not look", kept distinct from "nothing is wrong":
#          docker unreadable, `find` RC outside {0,1}, the find exceeding its bound (124), or the
#          Jellyfin positive-control database missing from the result set. Each prints UNKNOWN
#          rather than 0 and increments FAILURES.
#       C. A VENDORED FILE HAVING DRIFTED — repo-vs-host sha256 mismatch on any of audio.bash,
#          sabnzbd beets-config.yaml or the survivor config.yaml.
#       D. THE DRIFT BLOCK BEING BLIND — no output, RC 124, any other non-zero, a short answer
#          (fewer than 3 comparison lines), or an unrecognised label. All UNKNOWN, all exit 1.
#       E. THE DRIFT BLOCK BEING RUN WITH A NON-DEFAULT DRIFT_APPDATA_ROOT. That override exists
#          ONLY to drive the could-not-look branch, so any non-default value forces red whatever
#          the comparison finds — it can never be used to make a red run report green.
#
#     CENSUS_CANDIDATE AND VENDORED_DRIFT_CANDIDATE ARE NOW IGNORED. Neither can disable its
#     block, and setting either to 0 does NOT switch anything off — they only ever asked for a
#     block early. There is deliberately no sentinel that skips either check; do not add one.
#
#     REMOTE_TIMEOUT WAS LEFT AT 120 s, on measurement rather than on hope: the census is the
#     slowest thing promoted here and it ran in 4 s (04-06 measured 6 s), both an order of
#     magnitude inside the bound. Raising it would have been a change made for no measured reason.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — A FIFTH FATAL BLOCK (THE extended.conf DESTRUCTIVE
#     SWITCHES) WAS ADDED 2026-09-14 (quick task 260914-a2y, closing code-review CR-01 and WR-01).
#
#     THIS IS THE SIXTH SUCH NOTICE IN THIS FILE, AND THE ORDINAL IS STATED BECAUSE IT IS EASY TO
#     GET WRONG — the brief that commissioned this block called it "the fourth", which would have
#     made the file lie about itself. Measured before writing: the notice headers above sit at five
#     distinct places, so this is the sixth header. The matching `grep -c` for the shared opening
#     phrase goes 6 -> 7, NOT 5 -> 6, and that is not a miscount: the notice at the top of this
#     file quotes the phrase inside its own body, an over-count the 02.1-15 notice below already
#     documents and declines to "fix". So the count has always run one ahead of the number of
#     notices, and a reader who greps expecting 6 has found the documented quirk, not a bug.
#
#     (AMENDED 2026-09-14 — THE ARITHMETIC ABOVE WAS CURRENT WHEN THIS NOTICE WAS WRITTEN AND IS
#     NOW ONE BEHIND. The SEVENTH notice, added by code review WR-09, takes the headers to seven
#     and the matching count to 8. The one-ahead quirk is unchanged and is still not to be
#     "fixed". Amended in place rather than left to be discovered, because a self-describing
#     count that has silently gone stale is worse than never having stated one.)
#
#     BLOCK ordinal and NOTICE ordinal are different numbers, and both are given deliberately: four
#     blocks could exit this script 1 before today — the music freeze harness, the consumers audit,
#     the Jellyfin transcode audit and the vendored-file drift block — so the block added below is
#     the FIFTH, announced by the SIXTH notice.
#
#     WHY IT EXISTS. Phase 4 removed the `beet` call from stacks/selfhosted/arrs/sabnzbd/audio.bash.
#     beets() there decides success by touching a sentinel and then looking for audio files NEWER
#     than it, and the removed call was the only writer that could ever produce one. The
#     `SUCCESS: Matched with beets!` branch is therefore STRUCTURALLY UNREACHABLE, and the `else`
#     at audio.bash:287 now runs on every music job — corroborated, not theorised, by plan 04-15's
#     window-2 block, which recorded `matching_delta=3 error_delta=3` across three real jobs. That
#     `else` contains `rm -rf "$1"/*`, gated ONLY by `requireBeetsMatch` being true. conversion()
#     has the same shape (WR-01): every ConversionFormat outside {FLAC, OPUS} falls through to a
#     second `rm -rf "$1"/*`. Both gates live in ONE host file that nothing in this repo asserted.
#
#     WHAT NOW EXITS THIS SCRIPT 1 THAT DID NOT BEFORE:
#       - `requireBeetsMatch` in the sabnzbd container's /config/extended.conf being anything other
#         than false, INCLUDING ABSENT. Absence is a failure, not a pass: audio.bash's test is
#         unquoted, so an unset variable makes `[` error with rc 2 and lands in the safe direction
#         BY ACCIDENT. That is not a property to depend on, so it is not treated as one.
#       - `ConversionFormat` being outside {FLAC, OPUS}, including absent.
#       - COULD NOT LOOK — each kept distinct from "the switches are safe", and each its own named
#         UNKNOWN rather than a shared one: the sabnzbd container absent or docker unavailable
#         (remote exit 3); the config missing or unreadable (4); the read succeeding but returning
#         no bytes (6); the read exceeding REMOTE_TIMEOUT (124); the host unreachable; a SHORT
#         ANSWER (anything other than exactly two label lines); or an unrecognised label.
#       - EITHER OVERRIDE BEING NON-DEFAULT. EXTCONF_HOST and EXTCONF_PATH exist ONLY to drive the
#         could-not-look branches, so any non-default value forces EXIT_CODE=1 whatever the
#         comparison finds. Neither can be used to make a red run report green.
#
#     WHAT IT DELIBERATELY DOES NOT DO: it does not vendor extended.conf, and that file must NOT be
#     added to the D-13 drift set. THIS REPOSITORY IS PUBLIC and the file carries five *ArrApiKey
#     fields. The values are asserted remote-side and only two labels come back — see (c) at the
#     block itself for why the review's "add a fourth _drift_pair" fix was declined.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — NO NEW BLOCK, A NEW FATAL CONDITION AT THREE EXISTING
#     SITES, 2026-09-14 (code review WR-09).
#     Same shape as the 02.1-15 notice above: nothing was folded in, no sixth script runs. Three
#     probes that were REPORT-ONLY are now fatal — the Traefik container probe, the Authelia
#     container probe, and the Traefik dashboard probe.
#
#     THIS IS THE SEVENTH SUCH NOTICE, and the arithmetic is restated because the sixth notice
#     states the version that was current when IT was written: there are now SEVEN notice headers,
#     and the count for the shared opening phrase goes 7 -> 8. It still runs exactly ONE ahead of
#     the number of headers, for the documented reason — the 02.1-10 note near the top of this
#     file writes that phrase out literally inside its own body. That quirk is deliberate; do not
#     reword a notice to flatter a grep.
#
#     BLOCK ordinal is UNCHANGED at five. There is no sixth block.
#
#     THIS REVERSES A PREVIOUS DELIBERATE DECISION, AND THE REVERSAL IS THE POINT. The comment at
#     those three sites used to decline this fix, on the reasoning that a confident wrong
#     diagnosis is not a false green — the reader is shown a red, so the defect was rated below
#     the CR-03 class and left legible rather than half-fixed. That reasoning is WITHDRAWN
#     (paraphrased, not quoted, per this file's convention). It answered the wrong question. All
#     three printed ❌ WITHOUT TOUCHING EXIT_CODE, so the estate's single health-check entry point
#     exited 0 — "healthy" to any caller reading the STATUS rather than the transcript — with
#     Traefik down, which takes every *.deercrest.info service with it. The README contract is
#     "exits 0 healthy, 1 on any violation". A red glyph inside the transcript of a run that
#     reports success is that contract being broken, not a stylistic wart.
#
#     WHAT OVERTURNED IT WAS EVIDENCE, NOT TASTE. The 2026-09-14 routine run recorded
#     `Traefik dashboard: ❌ Not accessible` while the script exited 0
#     (260914-a2y-SUMMARY.md:175-177). Not a hypothetical: a red sitting in the transcript of a
#     green run, on every invocation, for as long as that condition lasts.
#
#     ONE CORRECTION TO THE ABOVE, DATED 2026-09-15 (quick task 260915-k9p). The 2026-09-14
#     evidence stands as history and the reasoning above is unchanged — but the dashboard ❌ it
#     cites was NOT an estate fault. That probe curled an UNPUBLISHED PORT — plain HTTP to port
#     8080 on the loopback, which `traefik.yaml` has never published on the LXC host (the old
#     target URL is paraphrased rather than written out, this file's convention, so a mechanical
#     grep for it keeps returning zero) — so curl exit 7 was the correct
#     answer to a question the configuration never made, and making it fatal turned a probe that
#     could only ever be red into a permanent exit 1. The probe now asserts the real serving
#     chain — `https://traefik.deercrest.info/dashboard/` on the websecure entrypoint, pinned to
#     loopback, expecting the Authelia redirect — and the full argument is at the block itself.
#     WR-09's fatal-ness is UNCHANGED by that correction: all three sites still set EXIT_CODE=1,
#     and nothing here was downgraded back to report-only. What changed is only that the
#     dashboard site now measures something the configuration promises.
#
#     EACH SITE NOW DISTINGUISHES THREE ANSWERS RATHER THAN TWO: running / not running / COULD NOT
#     LOOK. And that is why the REMOTE `grep -q` had to go, which is the subtle half of this
#     change. With `set -o pipefail` and `grep -q` as the LAST stage, a bound expiry does NOT
#     surface: `timeout` exits 124, `grep -q` exits 1 on the empty stream, and pipefail returns
#     the RIGHTMOST non-zero status — so 124 was laundered into 1 and read as "the container is
#     not running". The container-count sites above escape this ONLY because `wc -l` exits 0.
#     Adding `pipefail` to these three would therefore have looked like a fix and fixed nothing.
#     So the probes now capture `docker ps` output with NO REMOTE PIPE, branch on the ssh status,
#     and do the matching LOCALLY.
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

# CANDIDATE -> PROMOTED (Phase 4). The constant below is the switch for the "Vendored-file drift
# (D-13)" block further down.
#
#   PROMOTED 2026-09-13 by plan 04-11, after the first green candidate run
#   (2026-09-13T09:39:43Z: `✅ vendored files match (3)`, this script RC 0 in 20 s). The block now
#   ALWAYS runs, VENDORED_DRIFT_CANDIDATE IS IGNORED AND CANNOT DISABLE IT, and a drifted or
#   unreadable comparison exits this script 1. See the sixth notice at the top of this file for
#   the full list of what that added to the fatal path.
#
# THE HISTORY IS KEPT, because the reason for the gate is the reason the promotion is safe.
# While the constant was 0, the block ran ONLY when the caller set VENDORED_DRIFT_CANDIDATE=1, and
# the routine invocation — `bash scripts/quick-health-check.sh`, no environment — set nothing, so
# the block printed one CANDIDATE line and touched neither EXIT_CODE nor anything else.
#
# Why it was gated at all, rather than simply switched on: the block compares the three VENDORED
# files in this repo against their runtime copies on LXC 100, and at the commit that introduced it
# two of those three had deliberately NOT been installed on the host yet (plan 04-11 installed
# them). Landing it ungated would have made the routine check red-by-design for a whole wave —
# precisely the permanent red the notice at the top of this file promises this script does not
# inherit, and a permanently-red check trains the reader to ignore it. The first run being red on
# REAL state was valuable and was kept: it is this block's driven negative control (04-10 named
# both undelivered files with both hashes). It was simply run deliberately, under the opt-in,
# rather than at everyone who typed the script. It is green now because the host was given the
# files, not because the comparison was loosened.
VENDORED_DRIFT_PROMOTED=1

# ENV OVERRIDES for the drift block, all ${VAR:-default} so a grep can prove they exist. Every one
# of them can only make the block REDDER. There is deliberately no success-producing override:
#   DRIFT_APPDATA_ROOT   the runtime tree the vendored copies are compared against. It exists ONLY
#                        to drive the could-not-look branch, so ANY non-default value forces
#                        EXIT_CODE=1 regardless of what the comparison finds. Pointing it somewhere
#                        harmless can therefore never be used to make a red run report green.
#   DRIFT_EXPECT_*       ADDITIVE expectations. When set, the host hash must equal the repo hash
#                        AND the override. Setting one can only turn a green file red; unsetting it
#                        restores the plain repo-vs-host assertion, never a skip.
DRIFT_APPDATA_ROOT="${DRIFT_APPDATA_ROOT:-/mnt/fast/appdata}"
DRIFT_EXPECT_AUDIO_BASH="${DRIFT_EXPECT_AUDIO_BASH:-}"
DRIFT_EXPECT_SABNZBD_BEETS_CONFIG="${DRIFT_EXPECT_SABNZBD_BEETS_CONFIG:-}"
DRIFT_EXPECT_SURVIVOR_BEETS_CONFIG="${DRIFT_EXPECT_SURVIVOR_BEETS_CONFIG:-}"

# ENV OVERRIDES for the "extended.conf destructive switches" block (CR-01/WR-01), added 2026-09-14.
# Same contract as DRIFT_APPDATA_ROOT above, and the precedent is stated explicitly because it is
# the only reason these are safe to exist at all: EVERY OVERRIDE HERE CAN ONLY MAKE THE BLOCK
# REDDER. Any non-default value of EITHER forces EXIT_CODE=1 regardless of what the comparison
# finds, so the negative controls can be driven without either one ever being usable to launder a
# red run into a green one. There is deliberately NO success-producing override, and no sentinel
# that skips the block; do not add one.
#   EXTCONF_HOST   the host running the sabnzbd container.
#   EXTCONF_PATH   a path INSIDE that container, NOT on the host. The file is read through
#                  `docker exec`, so this names the container's own filesystem. It is not bind
#                  mounted from the repo and it is not vendored — see (c) at the block itself.
EXTCONF_HOST="${EXTCONF_HOST:-root@172.16.1.159}"
EXTCONF_PATH="${EXTCONF_PATH:-/config/extended.conf}"

# ENV OVERRIDES for the TRAEFIK DASHBOARD PROBE, added 2026-09-15 (quick task 260915-k9p). Same
# contract as the four above, stated again rather than cross-referenced because it is the only
# reason these are safe to exist: EITHER ONE BEING NON-DEFAULT FORCES EXIT_CODE=1, whatever the
# probe then measures. They exist ONLY to drive that block's could-not-look and failed-measurement
# branches, so neither can ever be used to launder a red run green. There is deliberately NO
# success-producing override and NO sentinel that skips the block; do not add one.
#
# BOTH ARE READ BY THE DASHBOARD PROBE AND BY NO OTHER BLOCK IN THIS FILE. Every other remote call
# here hard-codes root@172.16.1.159, deliberately: widening these two into a file-wide host
# override would let one variable retarget the whole check, which is a much larger blast radius
# than the two negative controls they were added for.
#   DASH_HOST         the ssh target for the probe. Exists only to drive the 255 branch (point it
#                     at an unroutable address and the transport fails before curl runs).
#   DASH_RESOLVE_IP   the address `--resolve` pins traefik.deercrest.info:443 to. Exists only to
#                     drive the curl-failure branch (an address with nothing listening) and the
#                     124 branch (an unroutable address, which hangs until the remote bound kills
#                     it). It is NOT a way to point the probe at a different Traefik and call it
#                     healthy — any non-default value is fatal on its own.
DASH_HOST="${DASH_HOST:-root@172.16.1.159}"
DASH_RESOLVE_IP="${DASH_RESOLVE_IP:-127.0.0.1}"

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
# share a verdict. The sentinel is WRITTEN INTO by the watchdog immediately before it kills, so a
# NON-EMPTY sentinel afterwards is proof the bound is what ended the call.
#
# WR-10: THE SIGNAL IS THE CONTENT, NOT THE FILE'S EXISTENCE, AND THAT CHANGED 2026-09-14.
# This function used to create the file safely with `mktemp` and then IMMEDIATELY `rm -f` it,
# making the signal its later existence. That threw away the one thing mktemp is for: between the
# unlink and the watchdog's truncating write the path was predictable AND UNOWNED, so anything
# able to create a file there could pre-place a symlink and redirect that write somewhere else.
# There was also a fallback — a guessable "${TMPDIR:-/tmp}/qhc-bound.$$.$RANDOM", used UNGUARDED
# whenever mktemp was unavailable — which was worse again, because $$ and $RANDOM are not a
# substitute for an atomic exclusive create.
#
# Impact was low in practice: macOS gives each user a private TMPDIR and this script is typed
# interactively by its owner. It is fixed anyway because it was a NEEDLESS reintroduction of the
# exact race mktemp exists to close, sitting in the one function that GATES this entire file —
# and a health check whose own watchdog can be redirected is not a health check. The file is now
# kept for the whole call and `[ -s ]` reads it; the guessable fallback is GONE; and an
# unavailable mktemp is now a NAMED refusal rather than a silent downgrade.
#
# THE REFUSAL DOES NOT REUSE THE CALLER'S BRANCHES, deliberately. Returning non-zero here would
# have been read by both call sites as "the host is unreachable" — a confident wrong diagnosis,
# which is the one thing this whole block exists to prevent. It says what actually happened and
# exits. Driven under bash 3.2.57:
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
    # WR-10: created ONCE, atomically, and KEPT. No unlink-then-recreate, no guessable fallback.
    if ! sentinel=$(mktemp -t qhc-bound 2>/dev/null); then
        echo "⚠️  UNKNOWN — could not create the watchdog sentinel with mktemp."
        echo "  Without it NO remote call below can be bounded, and a hang would once again be"
        echo "  indistinguishable from a slow answer — the one failure mode that leaves no"
        echo "  transcript at all. This is UNKNOWN, not healthy, and it is specifically NOT a"
        echo "  finding that 172.16.1.159 is unreachable. Check TMPDIR, then re-run."
        exit 1
    fi
    "$@" </dev/null & cmd_pid=$!
    { sleep "$secs"; printf 'timeout' > "$sentinel"; kill -TERM "$cmd_pid" 2>/dev/null; } & watch_pid=$!
    wait "$cmd_pid" 2>/dev/null; rc=$?
    kill -TERM "$watch_pid" 2>/dev/null
    wait "$watch_pid" 2>/dev/null
    # NON-EMPTY, not merely present: mktemp leaves the file empty, and only the watchdog writes
    # into it. `-e` would now be true on every single call.
    [ -s "$sentinel" ] && BOUNDED_SSH_TIMED_OUT=1
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
# ⚠️  THE THREE SITES BELOW WERE REPORT-ONLY UNTIL 2026-09-14 AND ARE NOW FATAL (WR-09). The
# comment that used to sit here declined the fix, reasoning that a confident wrong diagnosis is
# not a false green because the reader is shown a red. That is WITHDRAWN — paraphrased rather
# than quoted, the same convention as the other withdrawn claims in this file, so a mechanical
# grep for it keeps returning zero. It measured the wrong thing: none of the three touched
# EXIT_CODE, so this script exited 0 with a ❌ in its own transcript and Traefik down. See the
# SEVENTH notice at the top of this file for the full argument and for the evidence that
# overturned the earlier decision.
#
# THE REMOTE `grep -q` IS GONE FROM BOTH CONTAINER PROBES, AND THAT IS NOT COSMETIC. It is the
# reason `set -o pipefail` could not have fixed these sites: with `grep -q` LAST, a bound expiry
# gives `timeout` 124 and `grep -q` 1, and pipefail returns the RIGHTMOST non-zero status — so
# 124 arrives as 1 and reads as "not running". `docker ps` output is therefore captured with NO
# REMOTE PIPE (so the ssh status is `docker ps`'s own), and the match is done locally.
#
# BRANCH ORDER IS THE HOUSE S1 ORDER, same as the drift and extended.conf blocks: empty output
# first, deferring when the status is 124 because a killed command usually produces none either;
# then 124; then any other non-zero; and only then is anything asserted.
echo -n "Traefik: "
TRAEFIK_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 "timeout $REMOTE_TIMEOUT docker ps --format '{{.Names}}'")
TRAEFIK_RC=$?   # ssh propagates the remote status — NO remote pipe, so 124 cannot be laundered
if [ -z "$TRAEFIK_OUT" ] && [ "$TRAEFIK_RC" -ne 124 ]; then
    echo "⚠️  UNKNOWN — the container list came back empty (ssh exit $TRAEFIK_RC)."
    echo "  Nothing was matched. This is NOT 'traefik is not running'."
    EXIT_CODE=1
elif [ "$TRAEFIK_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — 'docker ps' exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  This is NOT 'traefik is not running'. Most likely cause: dockerd wedged."
    EXIT_CODE=1
elif [ "$TRAEFIK_RC" -ne 0 ]; then
    echo "⚠️  UNKNOWN — could not list containers (ssh exit $TRAEFIK_RC)."
    echo "  This is NOT 'traefik is not running'."
    EXIT_CODE=1
elif printf '%s\n' "$TRAEFIK_OUT" | grep -q '^traefik$'; then
    echo "✅ Running"
    # Check if it's healthy
    STATUS=$(ssh -n $SSH_OPTS root@172.16.1.159 "timeout $REMOTE_TIMEOUT docker inspect traefik --format='{{.State.Health.Status}}' 2>/dev/null || echo 'no healthcheck'")
    echo "  Health: $STATUS"
else
    echo "❌ Not running"
    echo "  Traefik being down takes every *.deercrest.info service with it. This exits 1 as of"
    echo "  2026-09-14 (WR-09); it used to print this same line and exit 0."
    EXIT_CODE=1
fi

# Check Authelia — identical shape and identical reasoning to the Traefik probe above.
echo -n "Authelia: "
AUTHELIA_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 "timeout $REMOTE_TIMEOUT docker ps --format '{{.Names}}'")
AUTHELIA_RC=$?   # ssh propagates the remote status — NO remote pipe, so 124 cannot be laundered
if [ -z "$AUTHELIA_OUT" ] && [ "$AUTHELIA_RC" -ne 124 ]; then
    echo "⚠️  UNKNOWN — the container list came back empty (ssh exit $AUTHELIA_RC)."
    echo "  Nothing was matched. This is NOT 'authelia is not running'."
    EXIT_CODE=1
elif [ "$AUTHELIA_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — 'docker ps' exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  This is NOT 'authelia is not running'. Most likely cause: dockerd wedged."
    EXIT_CODE=1
elif [ "$AUTHELIA_RC" -ne 0 ]; then
    echo "⚠️  UNKNOWN — could not list containers (ssh exit $AUTHELIA_RC)."
    echo "  This is NOT 'authelia is not running'."
    EXIT_CODE=1
elif printf '%s\n' "$AUTHELIA_OUT" | grep -q '^authelia$'; then
    echo "✅ Running"
else
    echo "❌ Not running"
    echo "  Every *.deercrest.info route carries chain-authelia@file. This exits 1 as of"
    echo "  2026-09-14 (WR-09); it used to print this same line and exit 0."
    EXIT_CODE=1
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

# The Traefik dashboard probe.
#
# ⚠️  THIS PROBE ASKED THE WRONG QUESTION FROM THE DAY IT WAS WRITTEN UNTIL 2026-09-15 (quick task
# 260915-k9p). It curled `/dashboard/` over plain HTTP on port 8080 of LXC 100's loopback — the
# old target URL is paraphrased rather than written out, per this file's convention for a
# withdrawn claim, so a mechanical grep for it keeps returning zero. `traefik.yaml` publishes
# exactly FOUR ports to the host — 80, 443, 3023, 3024 — and 8080 is not among them, confirmed
# live by `docker port traefik`. So `:8080` HAS NEVER EXISTED ON THE LXC HOST, curl exit 7
# (connection refused) was the CORRECT answer, and this probe was a PERMANENT RED asserting
# something the configuration never promised. WR-09 then made that branch fatal, which turned it
# into a permanent exit 1 on a healthy estate — the single red that kept this script, the estate's
# only health-check entry point, at 1 while every other block was green.
#
# THE FIX WAS THE PROBE, NOT THE ESTATE, AND NOTHING ABOUT THE ESTATE WAS TOUCHED. In particular
# 8080 WAS NOT PUBLISHED and must not be: `traefik.yaml:48` declares
# `--entrypoints.traefik.address=:8080` and `:57` binds `--metrics.prometheus.entrypoint=traefik`
# to it, so that entrypoint is load-bearing for the monitoring stack CONTAINER-INTERNALLY. It is
# correct that it is unreachable from the host. Do not "fix" this by adding a port mapping.
#
# WHAT IT ASSERTS NOW. The dashboard is really served at `https://traefik.deercrest.info` on the
# `websecure` entrypoint by the `traefik-rtr` router behind `chain-authelia@file`
# (`traefik.yaml:118-126`). One GET over that route therefore proves FOUR things at once — the
# websecure entrypoint is listening, the Host-rule router matched, the certificate validated, and
# the Authelia middleware is in the path — which is strictly more than a loopback hit on an
# unpublished port could ever have proven.
#
# WHAT IT DELIBERATELY DOES NOT ASSERT, so nobody reads the green tick as more than it is:
#
#   * PUBLIC REACHABILITY. `--resolve traefik.deercrest.info:443:$DASH_RESOLVE_IP` pins the name
#     to the loopback, so the request goes to THIS estate's Traefik and nothing else. That is the
#     point: the probe cannot pass because Cloudflare is serving something else, and cannot fail
#     because public DNS or hairpin NAT broke. Plain DNS also answers 302 here, but it egresses
#     through Cloudflare and hairpins back, so a failure would be ambiguous. A green tick says
#     NOTHING about whether the dashboard is reachable from the internet.
#   * ANY AUTHENTICATED CONTENT. `curl` sends no cookies, so an authenticated 200 is unobtainable
#     from a script. Demanding one would have been a NEW permanent red — the same defect class
#     being fixed here. The pass condition is a PROTECTED answer, which is what the measured
#     healthy response is: 302 to `auth.deercrest.info` (measured 2026-09-15, `ssl_verify_result`
#     0 against the public CA).
#
# AND 200 IS A VIOLATION, NOT SUCCESS. An unauthenticated 200 from this route would mean
# `chain-authelia@file` is NOT in the path and the Traefik dashboard is being served to anyone who
# asks. It gets its own ❌ and its own wording. This is deliberate and it is the one thing the old
# 8080 probe could never have detected — it was checking a port that answers nothing.
#
# NO `--max-time` ON CURL, DELIBERATELY. The Linux-side `timeout $REMOTE_TIMEOUT` is the bound
# (house rule, point 3 of the four-point note above). `--max-time` would convert a hang into curl
# exit 28 — a REAL MEASUREMENT — and so erase the 124 "could not look" distinction below.
#
# THE WR-09 PROPERTIES ARE CARRIED FORWARD UNCHANGED, and they are the reason this block is shaped
# the way it is rather than more compactly:
#
#   * THERE IS NO LOCAL PIPE IN FRONT OF THE CAPTURED STATUS. `VAR=$(ssh ... | grep -q 200)` makes
#     `$?` the GREP's, and `${PIPESTATUS[0]}` does not rescue an assignment — see the
#     container-count note above. So `DASH_RC=$?` sits on the line IMMEDIATELY below the capture,
#     and the split into status + redirect target happens on the lines AFTER that. Do not fold
#     either back into the assignment.
#   * ssh exit 255 means the TRANSPORT failed and curl never ran, and 124 means the remote bound
#     killed it. BOTH ARE "COULD NOT LOOK" AND NEITHER IS A MEASUREMENT. Any OTHER non-zero is
#     CURL's own exit — it ran and could not complete the request — which IS a real measurement of
#     inaccessibility. All three are fatal; they must never share a verdict, because "we could not
#     look" being recorded as "the dashboard route is broken" is the same misinformation as it
#     being recorded as "nothing is wrong".
#   * `%{http_code}` and `%{redirect_url}` come back as ONE space-separated field from ONE request.
#     Two curls could straddle a state change and report a status from before it with a redirect
#     target from after.
#
# The printed label `Traefik dashboard: ` is UNCHANGED ON PURPOSE — the failure tail at the bottom
# of this file and several prior SUMMARY records name it.
if [ "$DASH_HOST" != "root@172.16.1.159" ]; then
    echo "⚠️  DASH_HOST override in effect — this run cannot report the dashboard green"
    EXIT_CODE=1
fi
if [ "$DASH_RESOLVE_IP" != "127.0.0.1" ]; then
    echo "⚠️  DASH_RESOLVE_IP override in effect — this run cannot report the dashboard green"
    EXIT_CODE=1
fi
echo -n "Traefik dashboard: "
DASH_OUT=$(ssh -n $SSH_OPTS "$DASH_HOST" "timeout $REMOTE_TIMEOUT curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --resolve traefik.deercrest.info:443:$DASH_RESOLVE_IP https://traefik.deercrest.info/dashboard/")
DASH_RC=$?   # ssh propagates the remote status — NO local pipe above, see the note above
DASH_STATUS=$(printf '%s' "$DASH_OUT" | awk '{print $1}')
DASH_REDIR=$(printf '%s' "$DASH_OUT" | awk '{print $2}')
DASH_TO_AUTHELIA=0
case "$DASH_REDIR" in
    https://auth.deercrest.info/*) DASH_TO_AUTHELIA=1 ;;
esac
if [ "$DASH_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — the dashboard probe exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  Nothing was measured. This is NOT 'the dashboard route is broken'."
    EXIT_CODE=1
elif [ "$DASH_RC" -eq 255 ]; then
    echo "⚠️  UNKNOWN — the ssh to $DASH_HOST failed (exit 255), so curl never ran."
    echo "  Nothing was measured. This is NOT 'the dashboard route is broken'."
    EXIT_CODE=1
elif [ "$DASH_RC" -ne 0 ]; then
    echo "❌ Not reachable (curl exit $DASH_RC — it ran and could not complete the request)"
    echo "  This IS a measurement, unlike the two branches above. Exit 7 means nothing is"
    echo "  listening on 443 at $DASH_RESOLVE_IP; exit 60 means the certificate failed to validate."
    EXIT_CODE=1
elif [ "$DASH_STATUS" = "302" ] && [ "$DASH_TO_AUTHELIA" -eq 1 ]; then
    echo "✅ Protected (HTTP 302 → Authelia)"
elif [ "$DASH_STATUS" = "302" ]; then
    echo "❌ The router answered 302 but NOT to Authelia — redirect target '$DASH_REDIR'"
    echo "  The websecure entrypoint, router and TLS are fine; chain-authelia@file is not what"
    echo "  answered. Check the traefik-rtr middleware label."
    EXIT_CODE=1
elif [ "$DASH_STATUS" = "401" ]; then
    echo "✅ Protected (HTTP 401 from the Authelia chain)"
    echo "  The measured-normal answer to a curl request here is 302; 401 is accepted because"
    echo "  Authelia answers 401 rather than 302 for requests it reads as non-browser. Either one"
    echo "  proves entrypoint, router, TLS and middleware, so making 401 red would buy a future"
    echo "  false red for no gain."
elif [ "$DASH_STATUS" = "200" ]; then
    echo "❌ SUSPICIOUS — the dashboard answered 200 UNAUTHENTICATED. The chain-authelia@file"
    echo "  middleware is not in the path."
    echo "  THIS IS DELIBERATELY A VIOLATION AND NOT SUCCESS. curl sends no cookies, so a 200 here"
    echo "  cannot be an authenticated answer — it means the Traefik dashboard is being served to"
    echo "  anyone who asks. Check the traefik-rtr middlewares label in stacks/selfhosted/traefik."
    EXIT_CODE=1
elif echo "$DASH_STATUS" | grep -qE '^[0-9]+$'; then
    echo "❌ Unexpected answer from the dashboard route (HTTP $DASH_STATUS)"
    EXIT_CODE=1
else
    echo "⚠️  UNKNOWN — the probe exited 0 but returned '$DASH_OUT', which is not an HTTP status."
    echo "  Nothing was measured. This is NOT 'the dashboard route is broken'."
    EXIT_CODE=1
fi

# Vendored-file drift (D-13). THREE files in this repo are vendored copies of files that a
# container reads at runtime from /mnt/fast/appdata, and for all three the APPDATA COPY IS
# AUTHORITATIVE while the repo copy exists for review, history and exactly this comparison:
#
#   stacks/selfhosted/arrs/sabnzbd/audio.bash          -> .../arrs/sabnzbd/config/scripts/audio.bash
#   stacks/selfhosted/arrs/sabnzbd/beets-config.yaml   -> .../arrs/sabnzbd/config/scripts/beets-config.yaml
#   stacks/selfhosted/arrs/beets/config.yaml           -> .../arrs/beets/config/config.yaml
#
# WHY THIS BLOCK EXISTS (D-08). Upstream arr-scripts' setup.bash re-downloads audio.bash and
# beets-config.yaml from GitHub on container start. That revert path is real and measured, it is
# silent, and before this block NOTHING detected it. The `:ro` binds declared in sabnzbd.yaml stop
# a write from INSIDE the container; they do nothing about a host-side edit. This is the half that
# catches the host-side edit, which is why the two are described as a pair in that file.
#
# The comparison runs HOST-SIDE, both halves: `git show HEAD:<path>` inside /mnt/fast/stacks and
# sha256sum of the appdata copy. So the workstation's own working tree is irrelevant — a dirty or
# stale checkout here cannot produce a false green or a false red — and the host checkout being
# BEHIND origin shows up as real drift, which is correct: the host runs what the host has.
#
# FAIL-CLOSED, and never info(). "Could not look" and "the files match" are different answers and
# must not share a verdict (the CR-01 defect this estate spent four plans repairing). Every UNKNOWN
# branch below sets EXIT_CODE=1. The branch ORDER is the house S1 order and matters: empty output
# first (a zero-byte or never-started remote exits 0 with no output, which ONLY the empty test
# catches), deferring to 124 so a killed command is not reported as an unreachable host; then 124;
# then any other non-zero; and only then is anything asserted.
#
# The remote string contains pipes, so it starts `set -o pipefail` and the ssh status is captured
# on the very next line with NO local pipe in the assignment — `timeout T cmd | sha256sum` would
# otherwise report the hash of an empty stream and exit 0. See the container-count note above.
DRIFT_RUN=0
if [ "$VENDORED_DRIFT_PROMOTED" = "1" ]; then
    DRIFT_RUN=1
elif [ "${VENDORED_DRIFT_CANDIDATE:-0}" = "1" ]; then
    DRIFT_RUN=1
fi

if [ "$DRIFT_RUN" -eq 0 ]; then
    # UNREACHABLE since the 2026-09-13 promotion (VENDORED_DRIFT_PROMOTED=1 forces DRIFT_RUN=1
    # whatever VENDORED_DRIFT_CANDIDATE says). Kept as a fail-closed tell, and it sets EXIT_CODE:
    # if this ever prints, someone has set the constant back to 0 and NOTHING was compared.
    echo "⚠️  UNKNOWN — the vendored-file drift block did NOT run: VENDORED_DRIFT_PROMOTED has been set back to 0."
    echo "  Nothing was compared. This is NOT 'the vendored files match'."
    EXIT_CODE=1
else
    echo "Vendored-file drift:"
    DRIFT_ROOT_OVERRIDDEN=0
    if [ "$DRIFT_APPDATA_ROOT" != "/mnt/fast/appdata" ]; then
        DRIFT_ROOT_OVERRIDDEN=1
        echo "  ⚠️  DRIFT_APPDATA_ROOT override in effect — this run cannot report the vendored files green"
        EXIT_CODE=1
    fi
    DRIFT_CMD="set -o pipefail; cd /mnt/fast/stacks || exit 3
_drift_pair() {
  r=\$(timeout $REMOTE_TIMEOUT git show \"HEAD:\$2\" | sha256sum | cut -d' ' -f1) || exit 4
  h=\$(timeout $REMOTE_TIMEOUT sha256sum \"\$3\" | cut -d' ' -f1) || exit 5
  echo \"\$1 repo=\$r host=\$h\"
}
_drift_pair audio.bash stacks/selfhosted/arrs/sabnzbd/audio.bash \"$DRIFT_APPDATA_ROOT/arrs/sabnzbd/config/scripts/audio.bash\"
_drift_pair sabnzbd-beets-config.yaml stacks/selfhosted/arrs/sabnzbd/beets-config.yaml \"$DRIFT_APPDATA_ROOT/arrs/sabnzbd/config/scripts/beets-config.yaml\"
_drift_pair survivor-config.yaml stacks/selfhosted/arrs/beets/config.yaml \"$DRIFT_APPDATA_ROOT/arrs/beets/config/config.yaml\""
    DRIFT_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 "$DRIFT_CMD")
    DRIFT_RC=$?   # ssh propagates the remote status — NO local pipe above, see the note above
    if [ -z "$DRIFT_OUT" ] && [ "$DRIFT_RC" -ne 124 ]; then
        echo "  ⚠️  UNKNOWN — could not look: the drift comparison produced no output (ssh exit $DRIFT_RC)."
        echo "  Nothing was compared. This is NOT 'the vendored files match'."
        EXIT_CODE=1
    elif [ "$DRIFT_RC" -eq 124 ]; then
        echo "  ⚠️  UNKNOWN — the drift comparison exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
        echo "  Nothing was compared. This is NOT 'the vendored files match'."
        EXIT_CODE=1
    elif [ "$DRIFT_RC" -ne 0 ]; then
        echo "  ⚠️  UNKNOWN — could not look (ssh exit $DRIFT_RC; 3 = no /mnt/fast/stacks checkout,"
        echo "  4 = 'git show HEAD:<path>' failed, 5 = the appdata copy could not be hashed)."
        echo "  Nothing was compared. This is NOT 'the vendored files match'."
        EXIT_CODE=1
    else
        DRIFT_LINES=$(printf '%s\n' "$DRIFT_OUT" | grep -c 'repo=')
        if [ "$DRIFT_LINES" -ne 3 ]; then
            echo "  ⚠️  UNKNOWN — expected 3 comparison lines, got $DRIFT_LINES. Nothing is asserted."
            echo "  A short answer is 'could not look', NOT 'the files that did report are fine'."
            EXIT_CODE=1
        else
            DRIFT_BAD=0
            while read -r d_label d_r d_h; do
                [ -z "$d_label" ] && continue
                d_repo=${d_r#repo=}
                d_host=${d_h#host=}
                case "$d_label" in
                    audio.bash)                d_exp="$DRIFT_EXPECT_AUDIO_BASH" ;;
                    sabnzbd-beets-config.yaml) d_exp="$DRIFT_EXPECT_SABNZBD_BEETS_CONFIG" ;;
                    survivor-config.yaml)      d_exp="$DRIFT_EXPECT_SURVIVOR_BEETS_CONFIG" ;;
                    *)
                        echo "  ⚠️  UNKNOWN — unrecognised comparison label '$d_label'; nothing asserted for it."
                        EXIT_CODE=1
                        DRIFT_BAD=$((DRIFT_BAD + 1))
                        continue
                        ;;
                esac
                if [ "$d_repo" != "$d_host" ]; then
                    echo "  ❌ $d_label DRIFTED — repo=$d_repo host=$d_host"
                    EXIT_CODE=1
                    DRIFT_BAD=$((DRIFT_BAD + 1))
                elif [ -n "$d_exp" ] && [ "$d_host" != "$d_exp" ]; then
                    echo "  ❌ $d_label DRIFTED — repo=$d_repo host=$d_host expected-override=$d_exp"
                    EXIT_CODE=1
                    DRIFT_BAD=$((DRIFT_BAD + 1))
                fi
            done <<< "$DRIFT_OUT"
            if [ "$DRIFT_BAD" -eq 0 ] && [ "$DRIFT_ROOT_OVERRIDDEN" -eq 0 ]; then
                echo "  ✅ vendored files match (3): audio.bash, sabnzbd beets-config.yaml, survivor config.yaml"
            fi
        fi
    fi
fi

# extended.conf destructive switches (CR-01, WR-01). Added 2026-09-14 by quick task 260914-a2y.
# See the SIXTH EXIT-CODE notice at the top of this file for what this added to the fatal path.
#
# (a) WHY IT EXISTS. Phase 4 stripped the `beet` call out of audio.bash. beets() at :269-301
#     touches /config/scripts/beets-match and then tests for audio files NEWER than that sentinel;
#     the stripped call was the only writer in that window that could ever produce one. So
#     `SUCCESS: Matched with beets!` at :286 is now STRUCTURALLY UNREACHABLE — not unlikely,
#     unreachable — and the `else` at :287 is taken on EVERY music job. That `else` contains
#     `rm -rf "$1"/*` at :290 behind nothing but `[ $requireBeetsMatch = true ]`. This is measured,
#     not theorised: plan 04-15's window-2 block recorded `matching_delta=3 error_delta=3` over
#     three real jobs — three error lines, zero success lines. conversion() has the identical shape
#     (WR-01): FLAC short-circuits at :220 and OPUS is handled at :226-234, while every other value
#     reaches a second `rm -rf "$1"/*` at :237 — which is also what makes the ffmpeg block at
#     :242-255 unreachable dead code. TWO destructive branches, ONE unversioned host file.
#
# (b) WHY THE FIX IS HERE AND NOT IN audio.bash. The vendored-drift block directly above asserts
#     BYTE-IDENTITY between this repo's audio.bash and the host copy. Patching the script in place
#     would turn that block red against the host — the obvious fix breaks the guard that makes the
#     file trustworthy in the first place. So the destructive branches are left exactly as upstream
#     ships them, and THE VALUES THAT DISARM THEM are asserted instead.
#
# (c) WHY extended.conf IS NOT VENDORED, AND MUST NOT BE ADDED TO THE D-13 DRIFT SET. The review's
#     first suggested fix was a fourth _drift_pair over a vendored copy. It is deliberately NOT
#     taken: THIS REPOSITORY IS PUBLIC, and that file carries five *ArrApiKey fields — empty today,
#     which is a fact about today and not a property. ASSERT THE VALUES; NEVER COPY THE FILE. All
#     matching happens remote-side and only two label lines come back. The single grep inside
#     _ec_val is anchored on the key name it is asked for, and the value it prints is taken from
#     that one matched line, so no other line of that file can structurally reach this transcript.
#
# (d) ReplaygainTagging IS DELIBERATELY OUT OF SCOPE — a decision, not an oversight. The review's
#     snippet names three switches; this block asserts THE TWO THAT GATE AN `rm -rf`.
#     ReplaygainTagging gates a tag WRITER (r128gain at audio.bash:266). That is a real concern
#     after the strip and may deserve its own assertion, but it is a correctness problem, not a
#     data-destruction one, and folding it in here would blur what a red in this block means.
#
# ONE DELIBERATE WIDENING OF THE REVIEW'S SNIPPET: it asserts ConversionFormat=FLAC alone. That
# would be a FALSE RED on a correct OPUS estate, because OPUS really is handled at :226-234 and
# never reaches the rm -rf. The set asserted here is {FLAC, OPUS} — the values that are actually
# safe, which is the property being guarded.
#
# ⚠️  THE VALUE TEST WAS A DEMONSTRATED FALSE GREEN UNTIL 2026-09-14, AND THE FIX IS THE SHAPE OF
# _ec_val BELOW (code review CR-02). The withdrawn reasoning is paraphrased rather than quoted,
# the same convention as the other withdrawn claims in this file: a false claim left in-band
# verbatim is one that gets re-copied, and it is also one a mechanical grep can no longer prove
# absent.
#
# WHAT WAS TRUE AND IS KEPT: extended.conf carries trailing comments on the same line as a value,
# and plan 04-12 measured an END-ANCHORED REGEX returning 0 against a CORRECT value for exactly
# that reason. So a `$` anchor on the match pattern, and `grep -x`, are still both wrong here.
#
# WHAT WAS WRONG: the block read "do not end-anchor the pattern" as licence for the value having NO
# RIGHT-HAND BOUNDARY AT ALL, and it asserted with `grep -q` — "does ANY line match" — over the
# whole file. Both halves were false greens, and both were DRIVEN:
#   - `ConversionFormat="FLACX"` matched `…ConversionFormat="?(FLAC|OPUS)"?` and reported ok, while
#     audio.bash:220 tests `= FLAC` EXACTLY and falls through to `rm -rf "$1"/*` at :237.
#   - `requireBeetsMatch="false"` followed by `requireBeetsMatch="true"` reported ok, while
#     audio.bash sources the file at :41 and BASH TAKES THE LAST ASSIGNMENT — effective value
#     `true`, which is precisely what arms the `rm -rf` at :290. Appending a line rather than
#     editing one in place is the normal way a sourced bash config gets modified.
#   - and the `found=` diagnostic took `sed -n 1p`, the FIRST match, so even a red verdict could
#     quote a line that was not the one in force.
#
# THE FIX IS NOT A BETTER REGEX; IT IS EXTRACT-THEN-COMPARE. _ec_val takes the LAST matching
# assignment (`tail -n 1`, matching `source` semantics), strips the key, and yields the value.
# The caller then compares the WHOLE value — `[ "$v" = false ]` and a `case` over {FLAC, OPUS} —
# which bounds it without putting a `$` anchor anywhere near a regex, so the 04-12 tolerance
# survives intact. The `found=` text is now that same extracted value, so a red always quotes the
# line that actually takes effect.
#
# THE QUOTE HANDLING IS ALSO A BOUNDARY, AND THE ORDER MATTERS. A double- or single-quoted value is
# taken VERBATIM up to its closing quote and is NOT whitespace-stripped, because
# `ConversionFormat="FLAC "` really does set a trailing space in bash and really does fail
# audio.bash's exact test. Only an UNQUOTED value gets the trailing comment and trailing blanks
# removed — which is what bash's own word splitting would do to it anyway. Do not "simplify" this
# into a single strip-quotes-then-trim pass; that reintroduces the `"FLAC "` false green.
#
# ABSENCE IS A FAILURE, NOT A PASS. audio.bash's `[ $requireBeetsMatch = true ]` is unquoted, so an
# unset variable makes `[` fail with rc 2, which an `if` reads as false: it lands in the safe
# direction BY ACCIDENT. Accidental safety is not a property worth asserting against, so an absent
# key is treated exactly like a wrong one.
#
# FAIL-CLOSED, house S1 branch order, same as the drift block: empty output first (deferring when
# the status is 124, because a killed command usually produces no output either), then 124, then
# any other non-zero, and only then is anything asserted. The remote string contains pipes, so it
# starts `set -o pipefail`, and the ssh status is captured on the VERY NEXT LINE with no local pipe
# in the assignment — see the container-count note above for why both halves are necessary.
#
# ONE SHAPE HERE IS DELIBERATELY NOT COPIED FROM THE DRIFT BLOCK. That block counts its `repo=`
# lines, so an unrecognised label falls into the short-answer branch and its own `*)` case can
# never fire. This one counts NON-EMPTY lines, so a wrong label is still two lines and DOES reach
# the `*)` branch that names it. Both are fail-closed; this one can say which of the two went wrong.
echo "extended.conf destructive switches:"
EXTCONF_OVERRIDDEN=0
if [ "$EXTCONF_HOST" != "root@172.16.1.159" ]; then
    EXTCONF_OVERRIDDEN=1
    echo "  ⚠️  EXTCONF_HOST override in effect — this run cannot report the switches green"
    EXIT_CODE=1
fi
if [ "$EXTCONF_PATH" != "/config/extended.conf" ]; then
    EXTCONF_OVERRIDDEN=1
    echo "  ⚠️  EXTCONF_PATH override in effect — this run cannot report the switches green"
    EXIT_CODE=1
fi
# THE REMOTE-SIDE VALUE EXTRACTOR, IN ITS OWN SINGLE-QUOTED VARIABLE (CR-02). Two reasons, and
# both are the point rather than style:
#
#   1. SINGLE QUOTES MEAN ZERO ESCAPING. It is interpolated into the double-quoted EXTCONF_CMD
#      below, where every `$` and `"` would otherwise need a backslash. A value parser whose
#      correctness turns on counting backslashes is a parser nobody can review. Note the
#      consequence: NOTHING IN HERE IS EXPANDED LOCALLY — `$1`, `$_ec` and `$_ec_q` are all
#      resolved on LXC 100, by the remote shell, at the time the function runs.
#   2. IT CAN BE DRIVEN WITHOUT A HOST. Because it is a plain string holding a shell function and
#      it references only `$_ec` (the config text) and its `$1` (the key name), a test can `eval`
#      it locally with `_ec` set from a fixture and assert the extracted value — no ssh, no
#      docker, no production estate. That is how CR-02's negative controls are driven: a
#      duplicated key in the unsafe order, and `ConversionFormat="FLAC "`. Both must come back BAD.
#
# THE SINGLE QUOTE CHARACTER IS BUILT WITH `printf \47` RATHER THAN WRITTEN. A literal `'` cannot
# appear inside a single-quoted bash string without the `'\''` dance, and doing that three times
# inside a sed expression is exactly the unreviewable-escaping problem point 1 exists to avoid.
EXTCONF_PARSER='_ec_val() {
_ec_q=$(printf "\47")
_ec_l=$(printf "%s\n" "$_ec" | grep -E "^[[:space:]]*$1=" | tail -n 1)
[ -n "$_ec_l" ] || { printf "%s" "(absent)"; return 0; }
_ec_x=${_ec_l#*=}
_ec_x=$(printf "%s" "$_ec_x" | sed -e "s/^\"\([^\"]*\)\".*\$/\1/; t" -e "s/^$_ec_q\([^$_ec_q]*\)$_ec_q.*\$/\1/; t" -e "s/[[:space:]]*#.*\$//" -e "s/[[:space:]]*\$//")
[ -n "$_ec_x" ] || _ec_x="(empty)"
printf "%s" "$_ec_x"
}'

# Distinct remote exit codes so the UNKNOWN branch can NAME the cause instead of lumping every
# could-not-look into one verdict: 3 = docker exec failed (container absent, docker unavailable),
# 4 = the cat failed (path missing or unreadable), 6 = the read succeeded but returned no bytes.
# 124 is preserved explicitly at both probes rather than being collapsed into 3 or 4 — a bound
# expiry and a missing container are different answers.
EXTCONF_CMD="set -o pipefail
timeout $REMOTE_TIMEOUT docker exec sabnzbd true >/dev/null 2>&1
_ec_rc=\$?
[ \$_ec_rc -eq 124 ] && exit 124
[ \$_ec_rc -ne 0 ] && exit 3
_ec=\$(timeout $REMOTE_TIMEOUT docker exec sabnzbd sh -c 'cat \"$EXTCONF_PATH\"' 2>/dev/null)
_ec_rc=\$?
[ \$_ec_rc -eq 124 ] && exit 124
[ \$_ec_rc -ne 0 ] && exit 4
[ -n \"\$_ec\" ] || exit 6
$EXTCONF_PARSER
_ec_rbm=\$(_ec_val requireBeetsMatch)
if [ \"\$_ec_rbm\" = false ]; then
  echo 'requireBeetsMatch=ok'
else
  echo \"requireBeetsMatch=BAD found=\$_ec_rbm\"
fi
_ec_cf=\$(_ec_val ConversionFormat)
case \"\$_ec_cf\" in
  FLAC|OPUS) echo 'ConversionFormat=ok' ;;
  *) echo \"ConversionFormat=BAD found=\$_ec_cf\" ;;
esac
exit 0"
EXTCONF_OUT=$(ssh -n $SSH_OPTS "$EXTCONF_HOST" "$EXTCONF_CMD")
EXTCONF_RC=$?   # ssh propagates the remote status — NO local pipe above, see the note above
if [ -z "$EXTCONF_OUT" ] && [ "$EXTCONF_RC" -ne 124 ]; then
    case "$EXTCONF_RC" in
        3)
            echo "  ⚠️  UNKNOWN — the sabnzbd container is absent, or docker is unavailable on"
            echo "     $EXTCONF_HOST (remote exit 3)."
            ;;
        4)
            echo "  ⚠️  UNKNOWN — could not read $EXTCONF_PATH inside the sabnzbd container"
            echo "     (remote exit 4: the path is missing or unreadable)."
            ;;
        6)
            echo "  ⚠️  UNKNOWN — $EXTCONF_PATH read back EMPTY inside the sabnzbd container"
            echo "     (remote exit 6). An empty config is not a disarmed one: with no"
            echo "     requireBeetsMatch set at all, audio.bash:289 is an unquoted test on an unset"
            echo "     variable."
            ;;
        0)
            echo "  ⚠️  UNKNOWN — the switch read exited 0 but produced NO OUTPUT. A zero-byte or"
            echo "     never-started remote command exits 0 with nothing to say, and ONLY this test"
            echo "     catches it — plan 02.1-10 drove exactly that case (VALIDATION row 23), which"
            echo "     is why the empty test is first and the status test cannot replace it."
            ;;
        *)
            echo "  ⚠️  UNKNOWN — the ssh to $EXTCONF_HOST failed (exit $EXTCONF_RC); the host is"
            echo "     most likely unreachable."
            ;;
    esac
    echo "     Nothing was asserted. This is NOT 'the destructive switches are safe'."
    EXIT_CODE=1
elif [ "$EXTCONF_RC" -eq 124 ]; then
    echo "  ⚠️  UNKNOWN — the switch read exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "     Nothing was asserted. This is NOT 'the destructive switches are safe', and it is NOT"
    echo "     a failed assertion — the command never returned. Most likely cause: dockerd wedged."
    echo "     Distinguish it on atlantis (172.16.1.158): /proc/pressure/io 'full' near 100% WITH"
    echo "     AN IDLE CPU is the wedge; a busy CPU is not."
    EXIT_CODE=1
elif [ "$EXTCONF_RC" -ne 0 ]; then
    echo "  ⚠️  UNKNOWN — the switch read returned output but exited $EXTCONF_RC, so the answer"
    echo "     cannot be trusted. Nothing was asserted. This is NOT 'the destructive switches are"
    echo "     safe'."
    EXIT_CODE=1
else
    EXTCONF_LINES=$(printf '%s\n' "$EXTCONF_OUT" | grep -c '.')
    if [ "$EXTCONF_LINES" -ne 2 ]; then
        echo "  ⚠️  UNKNOWN — expected 2 switch lines, got $EXTCONF_LINES. Nothing is asserted."
        echo "     A short answer is 'could not look', NOT 'the switch that did report is fine'."
        EXIT_CODE=1
    else
        EXTCONF_BAD=0
        while IFS= read -r ec_line; do
            [ -z "$ec_line" ] && continue
            ec_label=${ec_line%% *}
            ec_rest=${ec_line#"$ec_label"}
            case "$ec_label" in
                requireBeetsMatch=ok)
                    ;;
                ConversionFormat=ok)
                    ;;
                requireBeetsMatch=BAD)
                    echo "  ❌ requireBeetsMatch is NOT false —${ec_rest}"
                    echo "     audio.bash:290 will 'rm -rf' the completed download on EVERY music"
                    echo "     job, because the beets() success branch at :286 is unreachable after"
                    echo "     the Phase 4 strip. Set requireBeetsMatch=\"false\" in $EXTCONF_PATH."
                    EXIT_CODE=1
                    EXTCONF_BAD=$((EXTCONF_BAD + 1))
                    ;;
                ConversionFormat=BAD)
                    echo "  ❌ ConversionFormat is neither FLAC nor OPUS —${ec_rest}"
                    echo "     audio.bash:237 will 'rm -rf' any completed download containing a"
                    echo "     FLAC (WR-01): the ffmpeg path at :242-255 that would have converted"
                    echo "     it is unreachable dead code."
                    EXIT_CODE=1
                    EXTCONF_BAD=$((EXTCONF_BAD + 1))
                    ;;
                *)
                    echo "  ⚠️  UNKNOWN — unrecognised label '$ec_label'; nothing asserted for it."
                    EXIT_CODE=1
                    EXTCONF_BAD=$((EXTCONF_BAD + 1))
                    ;;
            esac
        done <<< "$EXTCONF_OUT"
        if [ "$EXTCONF_BAD" -eq 0 ] && [ "$EXTCONF_OVERRIDDEN" -eq 0 ]; then
            echo "  ✅ extended.conf switches disarmed (2): requireBeetsMatch=false, ConversionFormat in {FLAC,OPUS}"
        fi
    fi
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
    # CROSS-FILE CONTRACT with scripts/check-music-freeze.sh. This selector is the consumer of
    # that file's summary labels, and it lives in a different file from the thing it depends on,
    # so the coupling can only be kept true by saying out loud what it selects. The anchor is the
    # literal heading `📊 7. Summary`; the labels selected are:
    #     tagger-class          unclassified          declared rw         ownership mismatches
    #     tagger definitions    beets databases       tagger databases    retired paths present
    #     rw on Music           tagger-capable
    # Renaming any of those labels in check-music-freeze.sh, or renumbering that heading, MUST
    # change this file in the same commit. A grep that selects nothing looks exactly like a check
    # with nothing to report, which is how the WR-09 coupling broke silently once already.
    #
    # The six Phase 4 tokens on the last two lines select section 6b's census counters. 6b is
    # PROMOTED (TAGGER_CENSUS_PROMOTED=1 in check-music-freeze.sh) and prints those counters on
    # every routine run, so THESE TOKENS ARE LIVE.
    #
    # CORRECTED 2026-09-14 (code review WR-05). This note used to tell a future editor the exact
    # opposite — that the six tokens matched nothing until plan 04-11 promoted the section — and
    # that is the dangerous direction, because acting on it FAILS SILENTLY. Deleting one of these
    # tokens does not fail this block: SUMMARY stays non-empty because the four original tokens
    # still match, `✅ Intact` still prints, and a census counter simply disappears from the
    # output with nothing saying so. That is precisely the silent coupling break the paragraph
    # above exists to prevent, which is why a stale comment here was worse than a stale comment
    # anywhere else in the file. Change both files together.
    SUMMARY=$(echo "$MUSIC_OUT" | sed -n '/^📊 7\. Summary/,$p' \
              | grep -E 'tagger-class|unclassified|declared rw|ownership mismatches|tagger definitions|beets databases|tagger databases|retired paths present|rw on Music|tagger-capable')
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
    # Extended 2026-09-14 (quick task 260914-a2y) when the extended.conf switch block was added.
    # Updated in the SAME COMMIT as the block itself, deliberately: plan 02.1-15 was bitten by
    # exactly this omission, and a tail that lists every block except the one that failed sends the
    # reader to the green ones.
    # Extended again 2026-09-14 (code review WR-09) when the Traefik, Authelia and dashboard
    # probes became fatal. Same discipline as the two amendments above: the tail is updated in
    # the SAME COMMIT as the sites that can now reach it, because a tail that lists every block
    # except the one that failed sends the reader to the green ones.
    echo "❌ Health check FAILED. The failing block is whichever one above carries a ❌ or a ⚠️ —"
    echo "   that is any of: the Traefik or Authelia container probes, the Traefik dashboard"
    echo "   probe, the container counts, the music freeze harness, the consumers audit, the"
    echo "   Jellyfin transcode retention audit, the vendored-file drift block, or the"
    echo "   extended.conf destructive-switch block."
    exit 1
fi
