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
#              (REVISED 2026-09-21 by plan 06-10, D-11 — the 2026-09-13 wording above is kept
#              visible because it is the record of a guard that fired on purpose. The expectation
#              is now TWO definitions, asserted BY NAME AND BY CLASS: flask.yaml as the ACTIVE
#              front end and beets/beets.yaml as the DORMANT CLI arm. A count of two whose members
#              are different files is a red, and a third unnamed definition still fails. The match
#              PATTERN was not narrowed — narrowing it is what would have disarmed the guard.)
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
#          (WIDENED 2026-09-21 by plan 06-10, D-03: a FOURTH pair, the vendored beets-flask config
#          stacks/selfhosted/arrs/beets/flask-config.yaml against
#          /mnt/fast/appdata/arrs/beets/config/beets-flask/config.yaml.)
#       D. THE DRIFT BLOCK BEING BLIND — no output, RC 124, any other non-zero, a short answer
#          (fewer than 3 comparison lines — FOUR since 2026-09-21, see C), or an unrecognised
#          label. All UNKNOWN, all exit 1.
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
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — A SIXTH FATAL BLOCK (CONTAINER IMAGE DRIFT) WAS ADDED
#     2026-09-18 (quick task 260918-c12).
#
#     THIS IS THE EIGHTH SUCH NOTICE, AND THE OFFSET THE SIXTH AND SEVENTH NOTICES DESCRIBE HAS
#     CHANGED — measured, not assumed, before and after this edit:
#         headers  (`grep -c '^# ⚠️  EXIT-CODE BEHAVIOUR CHANGED'`)   7 -> 8
#         raw      (`grep -c 'EXIT-CODE BEHAVIOUR CHANGED'`)          8 -> 11
#     So the raw count now runs THREE ahead of the header count, not one. This notice alone adds
#     three matches: its own header, plus the two grep patterns quoted on the two lines directly
#     above — because, like the 02.1-10 note near the top of this file, it writes the phrase out
#     literally inside its own body, and it does so twice in order to state both counts exactly.
#
#     STATED PRECISELY RATHER THAN ROUNDED, because this file's own convention is that a
#     self-describing count which has silently gone stale is worse than never having stated one,
#     and the sixth notice was already amended once for exactly that. The quirk is deliberate: do
#     not reword a notice to flatter a grep, and do not "fix" the offset by deleting the quotes.
#     If you need the number of notices, count the HEADERS — that grep is unambiguous and is the
#     one given first above.
#
#     BLOCK ordinal goes five -> SIX. scripts/check-drift.sh now also runs here.
#
#     WHAT NOW EXITS THIS SCRIPT 1 THAT DID NOT BEFORE:
#       - COULD NOT LOOK, each its own named UNKNOWN: 172.16.1.159 unreachable; the drift check
#         producing NO OUTPUT (which, for a while, will mostly mean the script has not reached
#         /mnt/fast/stacks yet — it lands by `git pull`); the remote command exceeding
#         REMOTE_TIMEOUT (124); the `📊 Summary` anchor having moved; the summary's FAILURES or
#         could-not-look counters being unreadable or reading UNKNOWN rather than a number.
#       - A FATAL FINDING REPORTED BY THE CHECK ITSELF — which is its own could-not-look count, or
#         its UNRESOLVABLE COUNT / NAME SET having moved. A third unresolvable container means a
#         new stale compose project, or a compose file this repo no longer carries.
#
#     ⚠️ WHAT IT EXPLICITLY CANNOT EXIT 1 ON: THE IMAGE DRIFT COUNT ITSELF. That is the whole
#     judgement of the block and it is stated here so nobody has to read the code to find it.
#     v1 of the drift instrument is ALERT-ONLY (D-01): nothing in it pulls, recreates or deploys,
#     and 14 containers were drifted on the day it shipped. Asserting drift at 0 would have made
#     the estate's single health entry point permanently red for a condition NOTHING IN THIS
#     REPOSITORY CAN CLEAR — the 01-09 trap, the same one that got the mode-bit assertions removed
#     from check-music-freeze.sh and that kept the `/` headroom floor green-with-margin rather than
#     aspirational. The count is REPORTED on the green path so it cannot grow unseen; the thing
#     that actually tells a human is the Grafana rule on an hourly timer into Telegram.
#     The promotion seam is the named constant IMAGE_DRIFT_PROMOTED below — read the comment there
#     before flipping it.
#
#     A NOTE ON THE EXIT CODES, because they look contradictory and are not: check-drift.sh EXITS 1
#     ON DRIFT ALONE, for a human who typed it. This block therefore does NOT branch on the exit
#     code alone — it reads `FAILURES total` and `could-not-look` out of that check's summary, both
#     of which deliberately EXCLUDE the drift count. A non-zero exit with both at 0 means "drift
#     exists, nothing is broken" and prints a tick. That split is a cross-file contract; see the
#     comment at the block itself and at check-drift.sh's own summary.
#
#     ⚠️ AND THIS IS THE FIRST FOLD-IN HERE WHOSE SUBJECT ALSO RUNS UNATTENDED. The KNOWN LIMIT
#     notice immediately below still applies to THIS script in full — nothing here is scheduled.
#     What changed is that the thing it now asks about IS scheduled (an hourly systemd timer feeding
#     node-exporter), which introduces a failure mode none of the other three blocks has: THE TIMER
#     CAN DIE AND LEAVE A FROZEN METRIC THAT READS EXACTLY LIKE HEALTH. That is why check-drift.sh
#     emits a last-success timestamp and why the Grafana rule set includes a STALENESS rule. This
#     block is unaffected by it — it runs the check live, in front of you — but do not read a green
#     here as evidence that the timer is alive. Different instruments, different questions.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — A SEVENTH FATAL BLOCK (THE LIBRARY UNDERSCORE-DIRECTORY
#     GUARD) WAS ADDED 2026-09-18 (plan 05-02, phase 5 D-22).
#
#     THIS IS THE NINTH SUCH NOTICE. Counts measured before and after this edit, not assumed —
#     using the two greps the eighth notice quotes (this notice deliberately does NOT write the
#     shared phrase out a second time in its own body, so it adds exactly one match to each):
#         headers   8 -> 9
#         raw      11 -> 12
#     The raw count therefore still runs THREE ahead of the header count. That offset is entirely
#     the eighth notice's two quoted patterns plus the 02.1-10 note near the top of this file; it
#     is unchanged by this edit, which is the point of stating it rather than rounding it.
#
#     BLOCK ordinal goes six -> SEVEN.
#
#     WHAT IT ASSERTS: zero directories whose basename begins with `_` exist ANYWHERE under
#     /mnt/tank/media/Music. This is ROADMAP Phase 5 criterion 4, which was ALREADY GREEN when the
#     phase opened (05-PREMEASURE.md § 6 measured zero) — so it is a guard to maintain, not work to
#     perform, and it is folded in here rather than budgeted for. Why it matters: Music Assistant
#     SILENTLY IGNORES underscore-prefixed folders and Jellyfin does not, so a staging-style name
#     leaking into the library makes the estate's two consumers diverge BY DESIGN, and NEITHER
#     REPORTS AN ERROR. That is the class of fault this whole file exists for — a wrong state with
#     no complaint attached to it.
#
#     WHAT NOW EXITS THIS SCRIPT 1 THAT DID NOT BEFORE:
#       - A REAL VIOLATION: one or more `_`-prefixed directories under the library.
#       - COULD NOT LOOK, kept distinct from the above and from a genuine zero: atlantis
#         (172.16.1.158) unreachable (ssh 255, so `find` never ran); the remote command exceeding
#         REMOTE_TIMEOUT (124); any other non-zero remote status; or output that is not a bare
#         integer. Three verdicts, never two — "could not look", "there are none" and "BROKEN" are
#         three different answers.
#
#     ⚠️ THIS IS THE FIRST BLOCK IN THIS FILE WHOSE PRIMARY READ TARGETS ATLANTIS RATHER THAN
#     LXC 100, so the WR-10 reachability gate at the top does NOT cover it — that gate probes
#     172.16.1.159. Atlantis unreachability is handled inside the block, as its own named UNKNOWN,
#     and line 81 of this file already names an unreachable atlantis as a fatal could-not-look for
#     the transcode fold-in. The target and the host are both overridable constants, and either
#     override forces a non-green run, per the DASH_HOST / EXTCONF_HOST convention.
#
#     ⛔ THE ADJACENT TEMPTATION IS FORBIDDEN, AND IT IS NAMED HERE SO THE NEXT PERSON MEETS THE
#     REASON RATHER THAN THE IDEA: do NOT add a `tank/downloads` ownership assertion to this file
#     (phase 5 D-25). The download client keeps writing as uid 3000 at roughly one job per 72
#     seconds, so such a check goes red on the next download — the exact permanent-red failure mode
#     phase 02.1's CR-01 spent four gap-closure plans repairing in the other direction, and the
#     same 01-09 trap that got the mode-bit assertions removed from check-music-freeze.sh.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — AN EIGHTH AND A NINTH FATAL BLOCK (THE D-03 MOUNT
#     ASSERTION AND THE D-04 THROWAWAY-`-l` ASSERTION) WERE ADDED 2026-09-21 (plan 06-10,
#     phase 6 D-03/D-04/D-11).
#
#     THIS IS THE TENTH SUCH NOTICE. Counts measured before and after this edit, not assumed —
#     using the two greps the eighth notice quotes (this notice does NOT write the shared phrase
#     out a second time in its own body, so it adds exactly one match to each):
#         headers    9 -> 10
#         raw       12 -> 13
#     The raw count therefore still runs THREE ahead of the header count, unchanged by this edit.
#
#     BLOCK ordinal goes seven -> NINE, because this one notice covers TWO new blocks. They are
#     kept as two blocks rather than one because they are DIFFERENT CLAIMS MEASURED BY DIFFERENT
#     INSTRUMENTS — a runtime mount table versus the content of the tracked tree — and folding them
#     together would blur what a red in either means.
#
#     WHAT NOW EXITS THIS SCRIPT 1 THAT DID NOT BEFORE:
#       F. THE FOURTH VENDORED PAIR. The existing drift block was widened from three pairs to four
#          (see C above). The hard-coded comparison count, the label `case` arm, the
#          DRIFT_EXPECT_FLASK_CONFIG variable and the green line all moved in the same edit; three
#          of four reporting is a short answer, which is a could-not-look, which is a red.
#          ⚠️ EXPECT THIS RED UNTIL PHASE 6 IS PUSHED AND THE HOST HAS PULLED. The comparison runs
#          host-side against /mnt/fast/stacks at ITS HEAD, and flask-config.yaml only entered git
#          in phase 6. `git show HEAD:<path>` on a host that does not yet carry the path exits 4,
#          which this block correctly reports as UNKNOWN rather than as a match. That is the block
#          working — the host runs what the host has — and it clears on `git pull --ff-only`.
#       G. THE D-03 MOUNT ASSERTION. One vendored beets config must be mounted into BOTH the active
#          front end and the dormant CLI arm, at the same source, at the same destination, `:ro` on
#          both; and /mnt/tank/media must be read-only on both (D-05, asserted from the runtime
#          rather than read from the file). A missing mount, a different source, or an rw flag is a
#          red. AN EMPTY `docker inspect` RESULT IS UNKNOWN, never "no bad mounts". A
#          `docker compose config` that renders `services: {}` — which is what a MISSING
#          `--profile manual` looks like on this estate, measured — is likewise UNKNOWN.
#       H. THE D-04 THROWAWAY-`-l` ASSERTION. No invocation-shaped `beet` line in an executable
#          file tracked under scripts/ or stacks/ may run without BOTH a `-l` outside
#          /config/library.db AND a `-c` overlay, because `-l` alone does not redirect
#          `statefile:`. Documentation (`*.md`) is scoped OUT of the assertion — two of this repo's
#          `.md` hits are historic quotations — but is COUNTED against a pinned baseline, so a new
#          copy-pasteable bare invocation in the runbook is its own red.
#       I. EITHER NEW BLOCK BEING BLIND, kept distinct from a genuine zero: 172.16.1.159
#          unreachable, the remote command exceeding REMOTE_TIMEOUT (124), any other non-zero
#          status, an empty inspect, a render with no bind mounts, a `git grep` status above 1, the
#          D-04 sentinel absent, a raw scan matching NOTHING (which means the pattern is wrong, not
#          that the tree is clean), or the comment strip removing nothing (which means it is not
#          stripping, so the narrowed count cannot be trusted). All UNKNOWN, all exit 1.
#       J. EITHER NEW BLOCK BEING RUN WITH A NON-DEFAULT OVERRIDE. Same contract as DASH_HOST and
#          EXTCONF_HOST: every D03_* knob, D04_DOC_BASELINE, D04_REPO_ROOT and DRIFT_REPO_ROOT
#          forces a non-green run when it is non-default, so none of them can launder a red run
#          into a green one. There is no success-producing override and no sentinel that skips
#          either block; do not add one.
#          ⚠️ DRIFT_REPO_ROOT AND D04_REPO_ROOT EXIST ONLY BECAUSE AN UNDRIVEABLE BRANCH IS AN
#          UNPROVEN BRANCH. Both blocks read a host-side git checkout, and both were hard-coded to
#          /mnt/fast/stacks, which meant their violation branches could only be driven by
#          committing a deliberate footgun — or a file that is not there yet — to the DEPLOYED
#          tree. Pointing them at a scratch checkout is how plan 06-10 drove those branches to red
#          and back to green without touching the estate. Neither can produce a pass.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — THE D-04 BLOCK GAINED TWO NEW FATAL CONDITIONS AND A
#     CORRECTED DIAGNOSIS, 2026-09-22 (plan 06-16, phase 6 CR-01 / WR-10 / IN-13).
#
#     THIS IS THE ELEVENTH SUCH NOTICE. Counts measured before and after this edit, not assumed —
#     using the two greps the eighth notice quotes (this notice does NOT write the shared phrase
#     out a second time in its own body, so it adds exactly one match to each):
#         headers   10 -> 11
#         raw       13 -> 14
#     The raw count therefore still runs THREE ahead of the header count, unchanged by this edit.
#
#     BLOCK ordinal does NOT move: nine blocks remain. This notice adds no block. It exists
#     because the D-04 block AS SHIPPED ON 2026-09-21 ASSERTED OVER AN EMPTY SET — measured on the
#     host's HEAD as raw 91, comment-stripped 35, invocation-shaped outside `*.md` ZERO — so the
#     green tick it printed for the whole of Phase 6 meant nothing. That is recorded here rather
#     than quietly corrected, because "the check was green" is the sentence this repo has to be
#     able to trust, and the previous ten notices are the only reason anyone would look.
#
#     WHAT NOW EXITS THIS SCRIPT 1 THAT DID NOT BEFORE:
#       K. A VACUOUS D-04 SCAN. If the invocation pattern matches NO executable line, that is now
#          UNKNOWN and fatal. Every `beet` call this repo makes from a script is built from a
#          variable, so a zero executable count means the pattern cannot SEE the invocations — it
#          does NOT mean there are none. The two sibling guards one screen above already refuse
#          exactly this reasoning for the raw count and the comment-stripped count; this is the
#          third, and it is the one that was missing when the defect landed.
#       L. THE EXEMPT INVOCATION COUNT LEAVING ITS PIN. Five invocation-shaped executable lines
#          are NAMED exemptions (three in phase06-oracle.sh, two in phase06-incremental-control.sh)
#          rather than assertions, for the three reasons set out in full in the D-04 block comment.
#          The count is pinned by D04_EXEMPT_BASELINE and a move is a red that prints every exempt
#          line, so a new non-compliant invocation cannot join that set in silence. The green line
#          also NAMES the exempt count, so a green D-04 always states how many lines it did not
#          assert over.
#          ⚠️ D04_EXEMPT_BASELINE CARRIES THE SAME ADDITIVE CONTRACT AS EVERY OTHER KNOB IN THIS
#          FILE: any non-default value prints a warning and forces EXIT_CODE=1, so setting the pin
#          to whatever the tree currently holds CANNOT produce a pass. There is still no
#          success-producing override anywhere in this file; do not add one.
#
#     WHAT CHANGED MEANING WITHOUT CHANGING THE VERDICT (WR-10 and IN-13, both diagnosis bugs):
#       * The D-04 remote program now tests for status 124 BEFORE collapsing everything above 1
#         into exit 4. `timeout` reports a kill as 124 and 124 > 1, so a wedged host was reported
#         as "'git grep' failed" and the block's own dedicated 124 branch was unreachable. The
#         verdict was right and the operator was sent to the wrong place.
#       * The D-03 CLI-render `cd` is now D03_REPO_ROOT rather than a hard-coded path, for the
#         same single reason DRIFT_REPO_ROOT and D04_REPO_ROOT exist: its `exit 3` branch could
#         not be driven, and an undriveable branch is an unproven branch. Same additive contract.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — NO NEW BLOCK, A NEW FATAL CONDITION AT AN EXISTING SITE,
#     2026-09-22 (plan 06-17, phase 6 WR-03).
#
#     THIS IS THE TWELFTH SUCH NOTICE. Counts measured before and after this edit, not assumed,
#     using the two greps the eighth notice quotes. This notice does NOT write the shared phrase
#     out a second time in its own body, so it adds exactly one match to each:
#         headers   11 -> 12
#         raw       14 -> 15
#     The raw count therefore still runs THREE ahead of the header count, unchanged by this edit.
#
#     BLOCK ordinal does NOT move: nine blocks remain. No new script runs here — the music
#     consumers audit was already folded in, and this changes how ONE of its exit statuses is
#     classified.
#
#     WHAT NOW EXITS THIS SCRIPT 1 THAT DID NOT BEFORE:
#       O. THE MUSIC-CONSUMERS FOLD-IN RUN WITH A NON-DEFAULT CONSUMERS_SCRIPT. Same additive
#          contract as DASH_HOST, EXTCONF_HOST, every D03_* knob, D04_REPO_ROOT and
#          DRIFT_REPO_ROOT: an overridden run cannot print `✅ Both consumers see the library`,
#          because the audit that answered was not the deployed one. This is the ONLY genuinely
#          new red in this notice, and it exists so the arm below can be driven at all — see the
#          knob's own comment for why an undriveable branch is an unproven branch, and why it
#          names a FILE rather than reusing one of the three *_REPO_ROOT knobs.
#
#     WHAT DID NOT CHANGE, stated because it is the substance of this notice: status 3 already
#     forced EXIT_CODE=1. It fell into the generic `❌ BROKEN (check-music-consumers.sh exit
#     $CONSUMERS_RC)` arm — same non-zero verdict, wrong label. The verdict was right and the
#     operator was sent to the wrong place, exactly as WR-10 was for the D-04 scan. This is
#     therefore mostly a RELABELLING notice, and it is written anyway because the eleventh notice
#     exists for the opposite reason and the pair is only readable if both are here.
#
#     WHAT ACTUALLY CHANGED, AND WHY IT IS NOT COSMETIC:
#       M. check-music-consumers.sh NOW HAS A THIRD EXIT CODE AT ALL. Before plan 06-17 it printed
#          the yellow "CONF-04 IS NOT CLOSED" block and then printed its GREEN BANNER and exited
#          ZERO, because `warn()` prints and touches no counter. This fold-in propagates that
#          status, so a CONF-04 regression AFTER Phase 7 discharges it — PreferNonstandardArtistsTag
#          reverting to `false`, one UI click, held nowhere in git — would have landed the artist
#          rows back on their baseline and exited 0 here too. A regression detector reporting the
#          regression in yellow text that nothing downstream reads. Exit 3 is what makes that
#          reachable by tooling; this arm is what stops it being reported as an instrument failure.
#       N. THE `📊 6. Summary` ANCHOR GUARD IS APPLIED ON THE NEW ARM TOO, reporting an absent
#          anchor as UNKNOWN. A renumbered heading must not be able to hide behind a newly-added
#          branch — WR-09's lesson, re-applied at the site WR-09 created.
#
#     HOW LONG IT STAYS NON-ZERO, stated so nobody tunes it out: for as long as CONF-04's Jellyfin
#     half is open. It discharges on ROADMAP entry criterion E6 and on nothing else. CONF-04 is NOT
#     closed by plan 06-17 and its two consumer verdicts are still recorded separately and never
#     summed — see the EXIT 3 paragraph in scripts/check-music-consumers.sh's header.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — NO NEW BLOCK, A NEW FATAL CONDITION AT AN EXISTING SITE,
#     2026-09-22 (plan 06-23, phase 6 GC-03 / GC-16).
#
#     THIS IS THE THIRTEENTH SUCH NOTICE. Counts measured before and after this edit, not assumed,
#     using the two greps the eighth notice quotes. This notice does NOT write the shared phrase
#     out a second time in its own body, so it adds exactly one match to each.
#
#     ⚠️ THE TWO NUMBERS AND THE CONSTANT DELTA THAT STOOD HERE ARE WITHDRAWN — R3-05, corrected
#     2026-09-23 by plan 06-30. They were measured honestly across THIS notice's own edit and were
#     invalidated LATER IN THE SAME ROUND by plan 06-26's tail repair — the line at the failure tail
#     stating that a new notice was deliberately not added, which in saying so added one raw match.
#     The stated delta went from three to four without anyone touching the sentence stating it, and
#     that was the THIRD drift of these counts. So the constant is gone rather than re-stated.
#
#     THE HEADER COUNT IS THE DURABLE ONE. A notice header is a deliberate, countable act; the raw
#     count is a side effect of prose, and it is DELIBERATELY NOT PINNED ANYWHERE — for the same
#     reason 06-DISPOSITIONS-GAP.md records for the D-04 raw counts: writing a number into a file
#     that greps itself moves that number. If you need the number of notices, COUNT THE HEADERS.
#
#     THE TWO RECIPES, to run rather than to trust:
#         headers  /usr/bin/grep -c '^# ⚠️  EXIT-CODE BEHAVIOUR CHANGE[D]' scripts/quick-health-check.sh
#         raw      /usr/bin/grep -c 'EXIT-CODE BEHAVIOUR CHANGE[D]'        scripts/quick-health-check.sh
#     ⚠️ THE FINAL LETTER IS BRACKETED ON PURPOSE AND MUST STAY THAT WAY. `CHANGE[D]` is a valid
#     grep pattern that matches every real occurrence, while these two recipe lines are NOT
#     themselves occurrences — so a recipe written in band does not perturb the number it asks you
#     to measure. Unbracketing it would add two raw matches and re-create the exact defect this
#     correction exists to retire. /usr/bin/grep by absolute path because the operator's zsh aliases
#     grep to ugrep. Both figures for 2026-09-23 are recorded, as DATED OBSERVATIONS AND NOT PINS,
#     in .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-30-qhc-census-and-counts.txt
#     — and nothing in this file reads from that artifact.
#
#     NO FOURTEENTH NOTICE WAS ADDED FOR THIS CORRECTION, AND THAT IS A DECISION, NOT AN OVERSIGHT.
#     Plan 06-30 changes no exit code, no block count and no condition; the notice series exists for
#     BEHAVIOUR changes, not for corrections to its own arithmetic. The header count was 13 before
#     that plan and is 13 after it.
#
#     ⚠️ THE THREE EARLIER INSTANCES OF THE WITHDRAWN SENTENCE ARE LEFT ALONE, DELIBERATELY. Each
#     earlier notice states the delta AS OF ITS OWN EDIT, each was accurate when written, and none
#     has been re-measured. Read them as DATED HISTORICAL RECORDS, never as claims about the file's
#     present state. Re-measuring them would turn three accurate historical statements into three
#     claims about a file state none of them describes.
#
#     BLOCK ordinal does NOT move: nine blocks remain. Nothing new runs here. This is one more arm
#     in the D-04 verdict ladder the eleventh notice describes, plus one widened regex branch in
#     the same block.
#
#     ⚠️ THE CONDITION LETTER IS P, NOT M. The eleventh notice stopped at L and the twelfth notice
#     then used M, N and O — out of alphabetical order, because its "what actually changed" section
#     was written below its "what now exits 1" section. M, N and O are therefore TAKEN. Measured by
#     `grep -nE '^#[[:space:]]+[A-Z]\.[[:space:]]' scripts/quick-health-check.sh`, which is the only
#     honest way to find the next free letter in this file; do not count forward from the last
#     notice's highest letter.
#
#     WHAT NOW EXITS THIS SCRIPT 1 THAT DID NOT BEFORE:
#       P. A VACUOUS D-04 **ASSERTED** SET, WHICH IS CONDITION K ONE NESTING LEVEL IN. Condition K
#          refuses a zero EXECUTABLE count. But the set the block actually iterates is
#          D04_INVOKE_ASSERT = executable MINUS exempt, and until this edit nothing guarded THAT
#          being zero. Delete or reshape the three scripts/check-beets-config.sh invocations and
#          the executable count falls to 5 while the exempt count stays 5: K does not fire (5 ≠ 0),
#          the exempt pin does not fire (5 = 5), the doc pin does not fire, and
#          `while … <<< "$D04_INVOKE_ASSERT"` over the empty string runs its body ZERO times, so
#          D04_BAD stays 0 and the block prints its ✅ line with `0 of 5` inside its own
#          parenthesis.
#          A GREEN TICK WHOSE OWN PARENTHESIS SAYS IT ASSERTED OVER NOTHING — verbatim the CR-01
#          defect the eleventh notice exists to record, reproduced one level down. That is not a
#          theory: it was DRIVEN, pre-fix and post-fix, over a synthetic all-exempt fixture, in
#          `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-23-d04-assert-vacuity.txt`.
#          Reported as ⚠️ UNKNOWN, not ❌, for the same reason K and its two siblings are: this file
#          keeps "could not look" distinct from "measured failure", and an empty asserted set is
#          the former.
#          ⚠️ THE GREEN CONDITION ITSELF ALSO NOW REQUIRES A NON-ZERO ASSERTED COUNT. Belt and
#          braces over the arm above, and it is worth the line because the tick's own text quotes
#          `$D04_N_ASSERT of $D04_N_EXE`: with this in place the tick and the number it prints
#          cannot disagree, whatever future edit is made to the ladder above it.
#
#     WHAT CHANGED MEANING WITHOUT CHANGING THE VERDICT (GC-16, a latent blind spot with NO current
#     instance in the tree):
#       * D04_INV_RE's FOURTH branch — the beets-binary variable-expansion branch added by plan
#         06-16 — anchored only on content start or immediately inside an opening quote, while its
#         three literal-token siblings in the same regex also anchored on a shell separator and on
#         a `docker` prefix. So that variable expansion after `&&`, and the same expansion inside a
#         `docker exec` line, were invocation-shaped and INVISIBLE to the scan. (Both shapes are
#         written out literally in the artifact named below, not here — see the paragraph at the
#         end of this notice for why.)
#         That asymmetry is the silent route by which the asserted set above can drop to
#         zero without any counter leaving its pin, which is why the two ship together. The anchor
#         set is now symmetric; the trailing flag-or-subcommand requirement is UNCHANGED, because
#         that half is what keeps the executable count at 8 rather than 26.
#         Proven ADDITIVE by measurement rather than argument: raw / comment-stripped /
#         invocation-shaped / executable / asserted / exempt / documentation are 199 / 98 / 10 / 8 /
#         3 / 5 / 2 with the old regex and with the new one. No pin moved.
#
#     ⚠️ THIS NOTICE DELIBERATELY ADDS **NO** NEW D-04 RAW MATCH, AND THAT IS STATED RATHER THAN
#     SILENT — the same convention the eleventh and twelfth notices use for the EXIT-CODE grep.
#     This file is itself inside D-04's scan scope (`scripts/`), so prose here that spells out the
#     literal token, or a variable name beginning with those four capitals, would move the raw
#     count that the additivity proof above is stated against. Every such shape is therefore
#     written out in the artifact instead. Measured, not assumed: running THIS FILE through the two
#     `-e` patterns the D-04 remote scan itself uses (read them off the D04_CMD assignment below —
#     they are deliberately not quoted again here, for the reason this paragraph is about) with
#     `grep -c -w -E` reads 35 before this notice and 35 after it, so the block's raw count is
#     untouched at 199. This is NOT "rewording to flatter a grep" in the sense the eighth
#     notice forbids — nothing here is reworded to change a number that is being reported; the
#     prose is placed where it does not perturb the instrument it is describing, and the choice is
#     recorded so the next reader can check it.
#
#     WHAT THIS NOTICE DOES **NOT** CLAIM. It does not discharge ROADMAP entry criterion E10, and it
#     does not close CONF-04. CR-01's carried residue stays carried — see the CR-01 row in
#     06-DISPOSITIONS.md. What closed here is the NESTED instance, and the blind spot next to it.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — A TENTH FATAL BLOCK (THE MUSIC IMPORT SWEEP) WAS ADDED
#     2026-09-26 (plan 07-03, phase 7 D-25, criterion 7 / IMPT-02).
#
#     NOTICE COUNT: measured AFTER this notice was written, with the header recipe the thirteenth
#     notice gives (driven first against a one-line control holding the real header text, which it
#     counted as 1). This notice does not write the shared phrase a second time in its own body.
#     The number is recorded in .planning/phases/07-pilot-12-albums-end-to-end/07-03-SUMMARY.md,
#     NOT here — writing it into a file that the recipe greps is how the earlier counts drifted.
#
#     BLOCK ordinal goes nine -> TEN.
#
#     WHAT IT ASSERTS: scripts/check-music-import.sh, run on LXC 100, finds ZERO of the three
#     criterion-7 damage classes over what beets imported — a `.N`-suffix path collision (DB rows
#     AND the on-disk files beside them), an empty mb_albumid on a non-DJ album item, and an
#     album-disc whose track count disagrees with its tracktotal (or whose items disagree about
#     it). The sweep reads library.db through Python sqlite in `mode=ro` inside beets-flask; it
#     issues no beets CLI invocation, so it needs no D-04 exemption. Phase 9 criterion 2 runs the
#     same script after every batch.
#
#     ⚠️ UNTIL THE FIRST PILOT IMPORT THIS BLOCK IS ⚠️ UNKNOWN BY DESIGN: the real library holds 0
#     items, and the sweep's per-class vacuity guard refuses to call an empty library clean. That
#     is the guard working, not a fault. It is never folded into green.
#
#     ⚠️ THE CONDITION LETTERS ARE Q, R AND S. P was the last letter in use, measured with
#     `grep -nE '^#[[:space:]]+[A-Z]\.[[:space:]]' scripts/quick-health-check.sh` before writing.
#
#     WHAT NOW EXITS THIS SCRIPT 1 THAT DID NOT BEFORE:
#       Q. A CRITERION-7 FINDING: the sweep exits 1 with one or more findings in any class.
#       R. THE SWEEP COULD NOT LOOK, OR HAD NOTHING TO LOOK AT, kept distinct from the above and
#          from a genuine zero: 172.16.1.159 unreachable or no output; the bound exceeded (124);
#          the summary anchor `📊 5. Summary` missing on an exit 0; or the sweep's own exit 3 —
#          container down, database unreadable, dump truncated, a directory unreadable, an empty
#          library, or ANY class with zero checkable rows. Three verdicts, never two.
#       S. THE FOLD-IN RUN WITH A NON-DEFAULT IMPORT_SWEEP_SCRIPT. Same additive contract as
#          CONSUMERS_SCRIPT (condition O): it may drive any arm and can never produce the tick.
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

# THE IMAGE-DRIFT PROMOTION SEAM. Deliberately 0, and it is NOT the same kind of constant as
# VENDORED_DRIFT_PROMOTED directly above it — read the difference before flipping it.
#
# VENDORED_DRIFT_PROMOTED switches a block ON. THIS ONE DOES NOT. The image-drift block below ALWAYS
# RUNS and is ALWAYS FATAL ON COULD-NOT-LOOK, whatever this constant says. What it controls is one
# narrower question: WHETHER THE DRIFT COUNT ITSELF IS AN ASSERTION.
#
#   0 (today)  the count is REPORTED on the green path. Drift alone cannot fail this script.
#   1          a non-zero drift count exits this script 1.
#
# WHY IT IS 0. v1 of the image-drift instrument is ALERT-ONLY (D-01): nothing in that change pulls,
# recreates or deploys anything, and 14 containers are drifted TODAY. Asserting drift at 0 would
# make the estate's single health entry point permanently red on the day it shipped, for a
# condition nothing in the repository can clear. THAT IS THE 01-09 TRAP — the same one that got the
# mode-bit assertions removed from check-music-freeze.sh, and the reason the `/` headroom floor in
# check-jellyfin-transcode.sh was chosen to be green with measured margin rather than aspirational.
# A permanently-red check trains the reader to ignore it, and then it is worth less than no check.
#
# SO WHAT TELLS A HUMAN? The Grafana rule, on the hourly timer, into Telegram — see
# stacks/selfhosted/monitoring/README.md § Image drift detection. THIS block's job is narrower and
# still worth having: make the number LEGIBLE ON THE GREEN PATH so it cannot grow unseen. A count
# that is neither asserted nor displayed is the CR-01 defect, and this file has paid for it once.
#
# FLIPPING THIS TO 1 IS THE D-03 AUTO-APPLY FOLLOW-UP, NOT A V1 DECISION. It only becomes reasonable
# once something can actually CLEAR the condition — i.e. once there is an apply path
# (IMAGE_DRIFT_AUTOAPPLY in scripts/check-drift.sh) or a standing commitment to pull promptly.
# Flipping it before then does not make the estate safer; it makes this script ignorable.
IMAGE_DRIFT_PROMOTED=0

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
#   DRIFT_REPO_ROOT      the host-side checkout the `git show HEAD:<path>` half reads. Added
#                        2026-09-21 by plan 06-10 for one reason and one reason only: WITHOUT IT
#                        THE FOURTH PAIR'S RED BRANCHES CANNOT BE DRIVEN. The repo half was
#                        hard-coded, so a pair whose file is not yet in the host's HEAD can only
#                        ever produce the exit-4 could-not-look branch — the comparison, the label
#                        arm and the DRIFT_EXPECT_* arm are all unreachable, and an undriveable
#                        branch is an unproven branch. Same contract as DRIFT_APPDATA_ROOT: ANY
#                        non-default value forces EXIT_CODE=1 whatever the comparison then finds,
#                        so pointing it at a convenient checkout can never report green.
DRIFT_REPO_ROOT="${DRIFT_REPO_ROOT:-/mnt/fast/stacks}"
DRIFT_EXPECT_AUDIO_BASH="${DRIFT_EXPECT_AUDIO_BASH:-}"
DRIFT_EXPECT_SABNZBD_BEETS_CONFIG="${DRIFT_EXPECT_SABNZBD_BEETS_CONFIG:-}"
DRIFT_EXPECT_SURVIVOR_BEETS_CONFIG="${DRIFT_EXPECT_SURVIVOR_BEETS_CONFIG:-}"
# FOURTH PAIR, added 2026-09-21 by plan 06-10 (D-03). Same ADDITIVE contract as the three above,
# stated again rather than cross-referenced because that is the only reason it is safe to exist:
# when set, the host hash must equal the repo hash AND this value, so setting it can only turn a
# green file red. Unsetting it restores the plain repo-vs-host assertion, never a skip.
DRIFT_EXPECT_FLASK_CONFIG="${DRIFT_EXPECT_FLASK_CONFIG:-}"

# ENV OVERRIDES for the D-03 MOUNT ASSERTION, added 2026-09-21 by plan 06-10. Same contract as
# DASH_HOST / EXTCONF_HOST: EVERY ONE OF THESE BEING NON-DEFAULT FORCES EXIT_CODE=1, whatever the
# assertion then measures. They exist ONLY to drive the block's red and could-not-look branches —
# pointing the expected source at a path that is not mounted must produce a RED that NAMES the
# mount, and it must never be usable to point the assertion at something convenient and call it
# healthy. There is deliberately NO success-producing override and NO sentinel that skips the
# block; do not add one.
D03_FLASK_CONTAINER="${D03_FLASK_CONTAINER:-beets-flask}"
# R3-01, 2026-09-23 (round-3 gap closure, plan 06-30). Rendered HERE, beside the definition and not
# at the use site, so a second future use cannot pick up the raw form. See the GC-17 census block at
# the vendored-drift comparison for the full rule and its bash dependency.
D03_FLASK_CONTAINER_Q=$(printf '%q' "$D03_FLASK_CONTAINER")
D03_BEETS_CONFIG_SOURCE="${D03_BEETS_CONFIG_SOURCE:-/mnt/fast/appdata/arrs/beets/config/config.yaml}"
D03_BEETS_CONFIG_DEST="${D03_BEETS_CONFIG_DEST:-/config/config.yaml}"
D03_MEDIA_SOURCE="${D03_MEDIA_SOURCE:-/mnt/tank/media}"
D03_CLI_COMPOSE="${D03_CLI_COMPOSE:-stacks/selfhosted/arrs/beets/beets.yaml}"
# R3-01, 2026-09-23 (plan 06-30). Same rule, same siting reason as D03_FLASK_CONTAINER_Q above.
D03_CLI_COMPOSE_Q=$(printf '%q' "$D03_CLI_COMPOSE")
D03_CLI_PROFILE="${D03_CLI_PROFILE:-manual}"
D03_CLI_PROFILE_Q=$(printf '%q' "$D03_CLI_PROFILE")
# D03_REPO_ROOT, added 2026-09-22 by plan 06-16 (IN-13). The CLI-render half `cd`s into the host
# checkout before `docker compose config`, and that `cd` was HARD-CODED while the two blocks either
# side of it grew overridable roots in the same 2026-09-21 commit, for the stated reason that an
# undriveable branch is an unproven branch. Its `exit 3` could therefore only be reached by
# breaking the deployed checkout. Same ADDITIVE contract as every other knob here: any non-default
# value forces EXIT_CODE=1, so it can only make the block redder.
#   ⛔ DO NOT REUSE DRIFT_REPO_ROOT OR D04_REPO_ROOT FOR THIS. The drift comparison, the D-04 scan
#   and the D-03 render are three DIFFERENT CLAIMS that merely happen to share a default path.
#   Sharing one knob would mean an override taken to drive one block's red branch silently moves
#   another block's verdict, and the run would report on a tree nobody asked it to look at.
D03_REPO_ROOT="${D03_REPO_ROOT:-/mnt/fast/stacks}"

# ENV OVERRIDES for the D-04 THROWAWAY-`-l` ASSERTION, added 2026-09-21 by plan 06-10. Same
# contract: any non-default value forces EXIT_CODE=1. D04_DOC_BASELINE is the PINNED count of
# invocation-shaped lines in DOCUMENTATION (see the block for why documentation is scoped out of
# the assertion but still counted), so the count cannot grow unseen.
D04_DOC_BASELINE="${D04_DOC_BASELINE:-2}"
# D04_REPO_ROOT exists for the same single reason as DRIFT_REPO_ROOT above — the scan reads the
# host's HEAD, so without it the violation branch cannot be driven without committing a deliberate
# footgun to the deployed checkout. Any non-default value forces EXIT_CODE=1.
D04_REPO_ROOT="${D04_REPO_ROOT:-/mnt/fast/stacks}"
# D04_EXEMPT_BASELINE is the PINNED count of invocation-shaped executable lines that are NAMED
# exemptions rather than assertions, added 2026-09-22 by plan 06-16. It is the exact precedent of
# D04_DOC_BASELINE above, applied to the other set the block does not assert over: an exemption
# that is not counted is an exemption that can grow. Same ADDITIVE contract — any non-default
# value prints a warning and forces EXIT_CODE=1, so the pin can only ever make the block redder
# and can never be used to make a moved count report green. The reason the five lines are exempt
# is stated IN FULL in the D-04 block comment, not here; do not raise this number without reading
# it, because raising it is how a real violation gets waved through.
D04_EXEMPT_BASELINE="${D04_EXEMPT_BASELINE:-5}"

# CONSUMERS_SCRIPT, added 2026-09-22 by plan 06-17 (WR-03). The music-consumers fold-in runs the
# audit from the host's DEPLOYED checkout, and that path was hard-coded. check-music-consumers.sh
# gained a third exit status (3 = CONF-04 measured and open) in the same plan that added the arm
# which classifies it — and that arm could not be driven without first deploying unmerged work to
# the live estate to make a health-check line up, which is the one thing this repo's execution
# notes forbid. Existing for the SAME SINGLE REASON as DRIFT_REPO_ROOT, D03_REPO_ROOT and
# D04_REPO_ROOT, and stated in their own words: AN UNDRIVEABLE BRANCH IS AN UNPROVEN BRANCH.
#   ⛔ DO NOT REUSE any of the three *_REPO_ROOT knobs for this, for the reason D03_REPO_ROOT gives
#   in full: they are different claims that merely share a default path, and one knob moving two
#   verdicts is how a run reports on a tree nobody asked it to look at. This one names a FILE, not
#   a root, because that is what the fold-in invokes.
#   Same ADDITIVE contract as every other knob in this file: a non-default value prints a warning
#   and forces EXIT_CODE=1, so an override can drive the arms but can NEVER produce the green tick.
CONSUMERS_SCRIPT="${CONSUMERS_SCRIPT:-/mnt/fast/stacks/scripts/check-music-consumers.sh}"

# IMPORT_SWEEP_SCRIPT, added 2026-09-26 by plan 07-03 (D-25). The music import sweep fold-in runs
# scripts/check-music-import.sh from the host's DEPLOYED checkout. The knob exists for the same
# single reason as CONSUMERS_SCRIPT: AN UNDRIVEABLE BRANCH IS AN UNPROVEN BRANCH — its exit-1 and
# exit-3 arms must be drivable from a stub without deploying unmerged work to the live estate.
#   ⛔ DO NOT REUSE CONSUMERS_SCRIPT OR ANY *_REPO_ROOT KNOB FOR THIS. They are different claims
#   that merely share a default directory; one knob moving two verdicts is how a run reports on a
#   file nobody asked it to look at. This one names ONE FILE, the one this fold-in invokes.
#   Same ADDITIVE contract as every other knob in this file: a non-default value prints a warning
#   and forces EXIT_CODE=1, so an override can drive the arms but can NEVER produce the green tick.
IMPORT_SWEEP_SCRIPT="${IMPORT_SWEEP_SCRIPT:-/mnt/fast/stacks/scripts/check-music-import.sh}"

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
# R3-01, 2026-09-23 (plan 06-30). This one is the sharp member of the set: the block it feeds reads
# the `requireBeetsMatch` guard, and until this edit the value crossed into the remote command
# string wrapped in hand-escaped double quotes inside a single-quoted remote `sh -c` — the exact
# shape the GC-17 prohibition names. The rendered form below now reaches the remote shell as a
# POSITIONAL PARAMETER of that `sh -c`, so it is never parsed as command text at all. See the
# EXTCONF_CMD assignment and the GC-17 census block for why.
EXTCONF_PATH_Q=$(printf '%q' "$EXTCONF_PATH")

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
# R4-07, 2026-09-23 (plan 06-35). BOTH HALVES: a code widening and a claim correction, in miniature.
# DASH_RESOLVE_IP reaches the dashboard probe's `curl --resolve` REMOTE command string, so it meets
# the GC-17 / R3-01 census criterion — which is "every knob that reaches a remote command string is
# rendered once, and only the rendered form is interpolated", deliberately broader than "every
# PATH" — and until this edit it crossed raw. The claim half is the half that mattered: no plan's
# census line named it, so running the recipe in that block as written surfaced this site as an
# un-rendered one that nothing owned.
# THE BOUND, from the review and not inflated: a split word makes `curl` fail LOUDLY rather than
# quietly, any non-default value already forces EXIT_CODE=1 at the override guard below, and the
# default contains no space. Nothing was broken; the census was.
# The rendered form is swapped into the REMOTE STRING ONLY. The override comparison and the
# operator echo in the failure arm keep the RAW value deliberately — rendering those would print
# backslashes at a human reading a diagnostic.
DASH_RESOLVE_IP_Q=$(printf '%q' "$DASH_RESOLVE_IP")

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
DASH_OUT=$(ssh -n $SSH_OPTS "$DASH_HOST" "timeout $REMOTE_TIMEOUT curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --resolve traefik.deercrest.info:443:$DASH_RESOLVE_IP_Q https://traefik.deercrest.info/dashboard/")
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

# Vendored-file drift (D-13, widened to FOUR pairs 2026-09-21 by plan 06-10 / D-03). FOUR files in
# this repo are vendored copies of files that a container reads at runtime from /mnt/fast/appdata,
# and for all four the APPDATA COPY IS AUTHORITATIVE while the repo copy exists for review, history
# and exactly this comparison:
#
#   stacks/selfhosted/arrs/sabnzbd/audio.bash          -> .../arrs/sabnzbd/config/scripts/audio.bash
#   stacks/selfhosted/arrs/sabnzbd/beets-config.yaml   -> .../arrs/sabnzbd/config/scripts/beets-config.yaml
#   stacks/selfhosted/arrs/beets/config.yaml           -> .../arrs/beets/config/config.yaml
#   stacks/selfhosted/arrs/beets/flask-config.yaml     -> .../arrs/beets/config/beets-flask/config.yaml
#
# THE FOURTH PAIR IS NOT THE CASE (c) BELOW ARGUES AGAINST. That argument (`:1183` at the time it
# was written) is about answering a MOUNT question with a HASH, and about vendoring a file carrying
# five *ArrApiKey fields into a public repository. flask-config.yaml is neither: it is a genuinely
# vendored file, already in git, that beets-flask reads at runtime from appdata at
# $BEETSFLASKDIR/config.yaml, and it carries no credential. The mount half of D-03 is asserted
# separately, from `docker inspect .Mounts`, in the block immediately after this one — because a
# hash cannot tell you WHICH CONTAINERS read the file it hashed.
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
    if [ "$DRIFT_REPO_ROOT" != "/mnt/fast/stacks" ]; then
        DRIFT_ROOT_OVERRIDDEN=1
        echo "  ⚠️  DRIFT_REPO_ROOT override in effect — this run cannot report the vendored files green"
        EXIT_CODE=1
    fi
    # ── GC-17, 2026-09-22 (round-2 gap closure, plan 06-26) ─────────────────────────────────────
    # EVERY OVERRIDABLE PATH THAT CROSSES INTO A REMOTE COMMAND STRING IS RENDERED ONCE WITH
    # `printf '%q'`, AND ONLY THE RENDERED FORM IS INTERPOLATED. A raw value word-splits on the
    # REMOTE shell, so an override naming a path that contains a space failed with a shell error
    # instead of driving the branch the knob exists to drive — and "an undriveable branch is an
    # unproven branch" is the ONLY reason any of these knobs exist. This is
    # scripts/phase06-oracle.sh's WR-08 defect reproduced in the sibling file WR-08's plan did not
    # own.
    #
    # ⚠️ THE CENSUS IS A RECIPE, NOT A NUMBER — CORRECTED 2026-09-23 BY R3-01 (plan 06-30).
    #   THE SENTENCE THAT STOOD HERE ASSERTED, AS A MEASURED FACT, A COUNT OF FOUR. GREP DISAGREED.
    #   Plan 06-26 owned four sites and rendered them: this one (DRIFT_REPO_ROOT), the D-03 CLI
    #   render's `cd` (D03_REPO_ROOT), the D-04 scan (D04_REPO_ROOT) and the consumers fold-in
    #   (CONSUMERS_SCRIPT). FIVE MORE WERE STILL RAW and the sentence did not know about them, so
    #   plan 06-30 rendered those too: D03_FLASK_CONTAINER, D03_CLI_COMPOSE, D03_CLI_PROFILE,
    #   MUSIC_UNDERSCORE_ROOT (TWO remote sites, one knob) and EXTCONF_PATH.
    #   AND THE LIST WAS STILL SHORT. Plan 06-35 rendered what round 4 found that neither line above
    #   covers: DRIFT_APPDATA_ROOT, which reaches the four `_drift_pair` call sites below as ONE
    #   knob rendered PER PAIR into four whole paths (R4-01), and DASH_RESOLVE_IP at the dashboard
    #   probe's `curl --resolve` string (R4-07).
    #   The two lines above are left EXACTLY as they stood, on purpose. They are accurate records of
    #   what those plans owned; rewriting them to match today's file would turn two true historical
    #   statements into two claims about a file state neither of them describes.
    #
    #   DO NOT TRUST THE LIST ABOVE AS A CURRENT TOTAL EITHER — it is a record of what past plans
    #   owned, not a measurement of what the file holds today. To RE-DERIVE the census, cross-
    #   reference the knob definitions against the remote call sites:
    #       /usr/bin/grep -nE '^[A-Z0-9_]+="\$\{[A-Z0-9_]+:-' scripts/quick-health-check.sh
    #       /usr/bin/grep -nE 'ssh (-n )?\$SSH_OPTS'          scripts/quick-health-check.sh
    #   and for each knob that reaches a remote command string, check that only its `_Q` form is
    #   interpolated. A number written in this file is a number that the next edit moves without
    #   touching the sentence that states it; a recipe is not.
    #
    #   THE SECOND GREP WAS WIDENED 2026-09-23 BY R4-08 (plan 06-35), AND THAT IS A CLAIM
    #   CORRECTION ONLY — the recipe is a comment, so nothing executable changed, no call site
    #   moved and no `_Q` was added by it. The old pattern required a literal `-n`, which MISSED
    #   TWO REMOTE CALL SITES: the two `bounded_ssh` reachability probes near the top of this file
    #   hand the options variable straight to ssh with NO `-n` between them, so the old haystack
    #   never contained them. A recipe offered as the durable replacement for a wrong number was
    #   itself under-counting its own haystack by two.
    #   (Those two sites are described here in prose rather than quoted, deliberately: reproducing
    #   their literal text in this comment would make this paragraph a hit for the very pattern it
    #   documents, and the recipe would then count itself. Find them with the widened grep above.)
    #   THE BOUND: NEITHER OF THOSE TWO SITES INTERPOLATES A KNOB TODAY — they pass a literal host
    #   and a literal command — so nothing was wrong in the file. The RECIPE was wrong.
    #   The alternation also keeps the recipe NON-SELF-MATCHING, which was checked by running it
    #   rather than assumed: the widened pattern carries more literal text than the one it replaced,
    #   and a recipe that counts its own comment line is the CR-01 / GC-03 shape this phase has
    #   already shipped twice. Run it: the hits are code lines only.
    #
    #   WHY THE CENSUS IS NOW A RECIPE, stated so the change does not read as fussiness: the
    #   EXTCONF_PATH site was not merely uncounted — it used the shape the ⛔ paragraph below
    #   FORBIDS BY NAME, three hundred lines beneath that prohibition, and it survived there for a
    #   full gap-closure round while this very sentence declared the class closed. A prohibition and
    #   a wrong census in the same comment block is how a reader concludes the work is done.
    #
    #   THE BOUND, and it has not changed: EVERY ONE of these is an ADDITIVE knob that cannot
    #   produce a green tick, every default value contains no spaces, and the EXTCONF_PATH injection
    #   consequence is static reasoning that was NEVER EXECUTED.
    #
    #   ⚠️ HOW MANY THERE ARE IS DELIBERATELY NOT STATED HERE — R4-05, corrected 2026-09-23 by plan
    #   06-35. A count stood in the sentence above, and THIS VERY EDIT MOVED IT, which is the entire
    #   argument: a number written into a file that greps itself is moved by the next edit without
    #   touching the sentence that states it. If you need the figure, RUN THE RECIPE ABOVE — that is
    #   what the recipe is for. This is the THIRD CONSECUTIVE ROUND in which that exact class
    #   shipped — GC-10, then R3-05, then R4-05, the last of them in a sibling file in the very
    #   round that corrected it here — which is why this block states lists and a recipe and carries
    #   no total at all.
    #
    #   Four of the five sites 06-30 owned failed CLOSED
    #   on a space — `find`/`docker` exit non-zero, `pipefail` fires, the existing could-not-look
    #   arm catches it — so they degraded a knob from "drives the branch" to "cannot be driven".
    #   The one exception worth naming is MUSIC_UNDERSCORE_ROOT, where both split words naming real
    #   directories makes `find` exit 0 and the count a silent union of two scans.
    #
    # ⚠️ THE BASH DEPENDENCY, STATED ONCE HERE AND CROSS-REFERENCED FROM THE OTHER THREE (GC-11).
    #   `printf '%q'` renders for BASH. A single-line path containing a space renders as a
    #   backslash escape that any POSIX shell accepts. A value containing a NEWLINE renders as
    #   bash ANSI-C `$'…'` quoting, which requires root's login shell on 172.16.1.159 to be bash.
    #   It is — bash 5.2, the same fact the `set -o pipefail` note above already relies on. And if
    #   it ever were not, the failure is LOUD: a syntax error and a non-zero ssh status, landing in
    #   this block's could-not-look arm. Not a quietly mangled command. Fail-closed, which is the
    #   same grading GC-11 gave the identical dependency in phase06-oracle.sh's remote_sh_c().
    # ⛔ DO NOT "fix" a future site of this shape by hand-escaping quotes inside the command string
    #   instead. A `\"` wrapper survives a space but not a quote and not a `$`, and a half-measure
    #   that LOOKS like a fix is worse here than the raw interpolation it replaces.
    #   THIS PARAGRAPH WAS RIGHT WHEN IT WAS WRITTEN AND IS UNCHANGED — AGAIN. What has now been
    #   wrong TWICE RUNNING is the sentence that followed it claiming the class was closed.
    #
    #   WHAT ROUND 3 SAID, AND WHY IT IS WITHDRAWN (R4-01, plan 06-35). R3-01 (plan 06-30) found the
    #   forbidden shape at the EXTCONF_PATH site three hundred lines below this paragraph and closed
    #   it — then wrote here that the paragraph had merely gone unapplied AT THAT ONE SITE, wording
    #   that implied the instance was singular and the class now closed. (Paraphrased, not quoted,
    #   the same convention the other withdrawn claims in this file use: a false statement left
    #   in-band verbatim is one that gets re-copied, and it is also one a mechanical grep can no
    #   longer prove absent.) THAT SENTENCE WAS FALSE WHEN IT WAS WRITTEN.
    #
    #   FOUR MORE INSTANCES WERE LIVE AT THAT MOMENT, eight to eleven lines BELOW this paragraph,
    #   inside the very DRIFT_CMD string the paragraph is embedded in: the four `_drift_pair` call
    #   sites, each interpolating the overridable DRIFT_APPDATA_ROOT inside a hand-escaped quote
    #   wrapper in the remote command string — precisely the shape forbidden three lines up. Round 4
    #   found them; plan 06-35 rendered all four, ONE WHOLE PATH PER PAIR, immediately below.
    #   So this is the SECOND CONSECUTIVE ROUND in which a documented-forbidden shape survived
    #   inside the file that documents it, and the second in which the CLOSING SENTENCE was the
    #   defect rather than the prohibition. The prohibition was never the weak part — which is also
    #   why the census above is a recipe and not a number.
    #
    #   THE BOUND, carried over intact, and NOT to be dramatised: these are ADDITIVE operator knobs,
    #   every default contains no space, a non-default DRIFT_APPDATA_ROOT ALREADY forces EXIT_CODE=1
    #   at the override guard above, a broken remote command lands in the could-not-look arm below,
    #   and there is NO PRIVILEGE CROSSING — the operator who can set the knob already has root on
    #   LXC 100. THE DEFECT IS THE CLAIM, NOT THE EXPLOIT.
    #
    #   Where a path must reach a remote `sh -c`, pass it as a POSITIONAL PARAMETER — the shape
    #   scripts/phase06-oracle.sh's remote_sh_c() uses, and the shape EXTCONF_CMD now uses. Where it
    #   reaches a remote function that ALREADY quotes its own parameter — the `_drift_pair` case
    #   below, whose body quotes "$3" — render the WHOLE word and interpolate it UNQUOTED.
    DRIFT_REPO_ROOT_Q=$(printf '%q' "$DRIFT_REPO_ROOT")
    # R4-01, 2026-09-23 (plan 06-35). ONE RENDERING PER PAIR, AND EACH RENDERS THE WHOLE
    # CONCATENATED PATH — not the root alone with a suffix bolted on afterwards. `printf '%q'`
    # renders a complete WORD: a suffix appended to the rendered value sits OUTSIDE the escaping and
    # reintroduces the split on the first space, which is the one way this fix ships broken while
    # looking right. The call sites below interpolate $DRIFT_AUDIO_Q, $DRIFT_SABBEETS_Q,
    # $DRIFT_SURVIVOR_Q and $DRIFT_FLASK_Q UNQUOTED, and that is correct rather than an oversight:
    # _drift_pair's body already quotes "$3", so the remote-side quoting is supplied there and the
    # call line must add none. See the ⛔ paragraph above for what was here before and why the
    # sentence that said the class was closed is withdrawn.
    DRIFT_AUDIO_Q=$(printf '%q' "$DRIFT_APPDATA_ROOT/arrs/sabnzbd/config/scripts/audio.bash")
    DRIFT_SABBEETS_Q=$(printf '%q' "$DRIFT_APPDATA_ROOT/arrs/sabnzbd/config/scripts/beets-config.yaml")
    DRIFT_SURVIVOR_Q=$(printf '%q' "$DRIFT_APPDATA_ROOT/arrs/beets/config/config.yaml")
    DRIFT_FLASK_Q=$(printf '%q' "$DRIFT_APPDATA_ROOT/arrs/beets/config/beets-flask/config.yaml")
    DRIFT_CMD="set -o pipefail; cd $DRIFT_REPO_ROOT_Q || exit 3
_drift_pair() {
  r=\$(timeout $REMOTE_TIMEOUT git show \"HEAD:\$2\" | sha256sum | cut -d' ' -f1) || exit 4
  h=\$(timeout $REMOTE_TIMEOUT sha256sum \"\$3\" | cut -d' ' -f1) || exit 5
  echo \"\$1 repo=\$r host=\$h\"
}
_drift_pair audio.bash stacks/selfhosted/arrs/sabnzbd/audio.bash $DRIFT_AUDIO_Q
_drift_pair sabnzbd-beets-config.yaml stacks/selfhosted/arrs/sabnzbd/beets-config.yaml $DRIFT_SABBEETS_Q
_drift_pair survivor-config.yaml stacks/selfhosted/arrs/beets/config.yaml $DRIFT_SURVIVOR_Q
_drift_pair flask-config.yaml stacks/selfhosted/arrs/beets/flask-config.yaml $DRIFT_FLASK_Q"
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
        echo "  ⚠️  UNKNOWN — could not look (ssh exit $DRIFT_RC; 3 = no $DRIFT_REPO_ROOT checkout,"
        echo "  4 = 'git show HEAD:<path>' failed, 5 = the appdata copy could not be hashed)."
        echo "  Nothing was compared. This is NOT 'the vendored files match'."
        EXIT_CODE=1
    else
        DRIFT_LINES=$(printf '%s\n' "$DRIFT_OUT" | grep -c 'repo=')
        # HARD-CODED, and moved from 3 to 4 in the same edit as the fourth _drift_pair, the label
        # `case` arm, the DRIFT_EXPECT_FLASK_CONFIG variable and the green line. All five move
        # together or this block reports three of four and reads green.
        if [ "$DRIFT_LINES" -ne 4 ]; then
            echo "  ⚠️  UNKNOWN — expected 4 comparison lines, got $DRIFT_LINES. Nothing is asserted."
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
                    flask-config.yaml)         d_exp="$DRIFT_EXPECT_FLASK_CONFIG" ;;
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
                echo "  ✅ vendored files match (4): audio.bash, sabnzbd beets-config.yaml, survivor config.yaml, flask-config.yaml"
            fi
        fi
    fi
fi

# D-03 — ONE VENDORED BEETS CONFIG, MOUNTED INTO BOTH CONTAINERS. Added 2026-09-21 (plan 06-10).
# See the TENTH EXIT-CODE notice at the top of this file for what this added to the fatal path.
#
# WHY THIS IS NOT A HASH. The block above asserts that the repo copy and the appdata copy of
# `beets/config.yaml` are byte-identical. That says nothing about WHO READS IT, and D-03's claim is
# about exactly that: ONE vendored beets config and ONE library.db are mounted into BOTH the active
# front end (beets-flask) and the dormant CLI arm (beets), which is the only thing that makes
# `BEETSDIR=/config` in flask.yaml and `library: /config/library.db` in the config resolve to the
# same file on both sides. A hash cannot answer a mount question. `docker inspect .Mounts` can.
#
# TWO DIFFERENT INSTRUMENTS FOR TWO DIFFERENT CONTAINER STATES, and that asymmetry is the point:
#   * beets-flask is RUNNING, so it is read from the RUNTIME — `docker inspect`. This is the WR-02
#     lesson: what a compose file declares and what the daemon actually attached are different
#     claims, and the one that matters is the daemon's.
#   * beets is DORMANT by design (`restart: "no"`, `profiles: ["manual"]`, commented out of
#     ../compose.yaml's include list), so there is nothing to inspect. It is RENDERED with
#     `docker compose config` instead — declared, not attached, and labelled as such below.
#     ⚠️ THE `--profile manual` FLAG IS LOAD-BEARING AND WAS MEASURED, NOT ASSUMED. Without it,
#     `docker compose -f beets/beets.yaml config` prints `services: {}` on this estate — a
#     perfectly valid YAML document with nothing in it, which a naive matcher reads as "no bad
#     mounts" and reports green. That is the row-22 shape again in a new costume.
#
# D-05 IS ASSERTED HERE TOO, FROM THE RUNTIME RATHER THAN FROM THE FILE. /mnt/tank/media must be
# read-only on BOTH containers for the whole of Phase 6. beets.yaml and flask.yaml both say so in
# comments; this block is the half that checks the daemon agrees.
#
# FAIL-CLOSED ON EVERY BRANCH, house S1 order (empty output first, deferring when the status is
# 124; then 124; then any other non-zero; and only then is anything asserted). AN EMPTY
# `docker inspect` RESULT IS `UNKNOWN`, NEVER "no bad mounts" — check-music-freeze.sh's row-22
# control already proved on this estate that an empty inspect must not satisfy a zero-test.
# NEITHER REMOTE STRING CONTAINS A PIPE, deliberately: with no pipe there is nothing for the bound
# to fail to bind through, the ssh status is the remote status, and the matching is done LOCALLY —
# which is the shape WR-09 arrived at after `grep -q` laundered a 124 into a 1.
echo "D-03 — one vendored beets config into both containers:"
D03_OVERRIDDEN=0
if [ "$D03_FLASK_CONTAINER" != "beets-flask" ] \
   || [ "$D03_BEETS_CONFIG_SOURCE" != "/mnt/fast/appdata/arrs/beets/config/config.yaml" ] \
   || [ "$D03_BEETS_CONFIG_DEST" != "/config/config.yaml" ] \
   || [ "$D03_MEDIA_SOURCE" != "/mnt/tank/media" ] \
   || [ "$D03_CLI_COMPOSE" != "stacks/selfhosted/arrs/beets/beets.yaml" ] \
   || [ "$D03_REPO_ROOT" != "/mnt/fast/stacks" ] \
   || [ "$D03_CLI_PROFILE" != "manual" ]; then
    D03_OVERRIDDEN=1
    echo "  ⚠️  a D03_* override is in effect — this run cannot report the mounts green"
    EXIT_CODE=1
fi
# GC-17, 2026-09-22 (plan 06-26). Rendered once, quoted, and it is the RENDERED form that is
# interpolated into the (ii) CLI-render command string below. See the full note at the vendored-file
# drift block above for why, and for the bash dependency `printf '%q'` carries (GC-11).
D03_REPO_ROOT_Q=$(printf '%q' "$D03_REPO_ROOT")
D03_BAD=0
D03_LOOKED=0

# --- (i) the ACTIVE front end, read from the runtime --------------------------------------------
D03_FLASK_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 "timeout $REMOTE_TIMEOUT docker inspect $D03_FLASK_CONTAINER_Q --format '{{range .Mounts}}{{.Source}} {{.Destination}} {{.RW}}
{{end}}'")
D03_FLASK_RC=$?   # ssh propagates the remote status — NO local pipe above
D03_FLASK_LINES=$(printf '%s\n' "$D03_FLASK_OUT" | grep -c '^/')
if [ "$D03_FLASK_LINES" -eq 0 ] && [ "$D03_FLASK_RC" -ne 124 ]; then
    echo "  ⚠️  UNKNOWN — 'docker inspect $D03_FLASK_CONTAINER' returned no mount lines (ssh exit $D03_FLASK_RC)."
    echo "  Nothing was asserted. This is NOT 'no bad mounts' — an empty inspect must never satisfy a zero-test."
    EXIT_CODE=1
elif [ "$D03_FLASK_RC" -eq 124 ]; then
    echo "  ⚠️  UNKNOWN — 'docker inspect $D03_FLASK_CONTAINER' exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  Nothing was asserted. This is NOT 'no bad mounts'."
    EXIT_CODE=1
elif [ "$D03_FLASK_RC" -ne 0 ]; then
    echo "  ⚠️  UNKNOWN — could not inspect $D03_FLASK_CONTAINER (ssh exit $D03_FLASK_RC)."
    echo "  Nothing was asserted. This is NOT 'no bad mounts'."
    EXIT_CODE=1
else
    D03_LOOKED=1
    D03_F_CFG=$(printf '%s\n' "$D03_FLASK_OUT" | awk -v d="$D03_BEETS_CONFIG_DEST" '$2==d {print $1" "$3}')
    if [ -z "$D03_F_CFG" ]; then
        echo "  ❌ $D03_FLASK_CONTAINER has NO mount at $D03_BEETS_CONFIG_DEST — the vendored beets config is not mounted"
        EXIT_CODE=1
        D03_BAD=$((D03_BAD + 1))
    else
        D03_F_CFG_SRC=${D03_F_CFG% *}
        D03_F_CFG_RW=${D03_F_CFG#* }
        if [ "$D03_F_CFG_SRC" != "$D03_BEETS_CONFIG_SOURCE" ]; then
            echo "  ❌ $D03_FLASK_CONTAINER: $D03_BEETS_CONFIG_DEST comes from '$D03_F_CFG_SRC', expected '$D03_BEETS_CONFIG_SOURCE'"
            EXIT_CODE=1
            D03_BAD=$((D03_BAD + 1))
        fi
        if [ "$D03_F_CFG_RW" != "false" ]; then
            echo "  ❌ $D03_FLASK_CONTAINER: $D03_BEETS_CONFIG_DEST is RW=$D03_F_CFG_RW, expected RW=false (:ro)"
            EXIT_CODE=1
            D03_BAD=$((D03_BAD + 1))
        fi
    fi
    D03_F_MEDIA=$(printf '%s\n' "$D03_FLASK_OUT" | awk -v s="$D03_MEDIA_SOURCE" '$1==s {print $3}')
    if [ -z "$D03_F_MEDIA" ]; then
        echo "  ❌ $D03_FLASK_CONTAINER has NO mount from $D03_MEDIA_SOURCE — D-05 cannot be asserted from this runtime"
        EXIT_CODE=1
        D03_BAD=$((D03_BAD + 1))
    elif [ "$D03_F_MEDIA" != "false" ]; then
        echo "  ❌ D-05 VIOLATED — $D03_FLASK_CONTAINER holds $D03_MEDIA_SOURCE at RW=$D03_F_MEDIA, expected RW=false"
        EXIT_CODE=1
        D03_BAD=$((D03_BAD + 1))
    fi
fi

# --- (ii) the DORMANT CLI arm, rendered rather than inspected -----------------------------------
D03_CLI_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 "cd $D03_REPO_ROOT_Q || exit 3; timeout $REMOTE_TIMEOUT docker compose --profile $D03_CLI_PROFILE_Q -f $D03_CLI_COMPOSE_Q config 2>/dev/null")
D03_CLI_RC=$?   # ssh propagates the remote status — NO local pipe above
# Normalise the long-form `volumes:` the renderer emits into `source target ro|rw`, LOCALLY.
# `read_only:` is EMITTED ONLY WHEN TRUE, so its ABSENCE means read-write — the default here is
# therefore `rw`, which is the fail-closed direction: a missing key can only make a row redder.
D03_CLI_MOUNTS=$(printf '%s\n' "$D03_CLI_OUT" | awk '
  /^[[:space:]]*-[[:space:]]*type:[[:space:]]*bind/ { if (s != "") print s, t, ro; s=""; t=""; ro="rw"; next }
  /^[[:space:]]*source:[[:space:]]/               { s=$2; next }
  /^[[:space:]]*target:[[:space:]]/               { t=$2; next }
  /^[[:space:]]*read_only:[[:space:]]*true/       { ro="ro"; next }
  END { if (s != "") print s, t, ro }
')
D03_CLI_LINES=$(printf '%s\n' "$D03_CLI_MOUNTS" | grep -c '^/')
if [ "$D03_CLI_LINES" -eq 0 ] && [ "$D03_CLI_RC" -ne 124 ]; then
    echo "  ⚠️  UNKNOWN — rendering $D03_CLI_COMPOSE yielded no bind mounts (ssh exit $D03_CLI_RC;"
    echo "  3 = no $D03_REPO_ROOT checkout). Nothing was asserted, and 'services: {}' is what a"
    echo "  MISSING --profile $D03_CLI_PROFILE looks like — it is NOT 'no bad mounts'."
    EXIT_CODE=1
elif [ "$D03_CLI_RC" -eq 124 ]; then
    echo "  ⚠️  UNKNOWN — rendering $D03_CLI_COMPOSE exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  Nothing was asserted. This is NOT 'no bad mounts'."
    EXIT_CODE=1
elif [ "$D03_CLI_RC" -ne 0 ]; then
    echo "  ⚠️  UNKNOWN — could not render $D03_CLI_COMPOSE (ssh exit $D03_CLI_RC)."
    echo "  Nothing was asserted. This is NOT 'no bad mounts'."
    EXIT_CODE=1
else
    D03_C_CFG=$(printf '%s\n' "$D03_CLI_MOUNTS" | awk -v d="$D03_BEETS_CONFIG_DEST" '$2==d {print $1" "$3}')
    if [ -z "$D03_C_CFG" ]; then
        echo "  ❌ the dormant CLI arm declares NO mount at $D03_BEETS_CONFIG_DEST — the two containers do not share one config"
        EXIT_CODE=1
        D03_BAD=$((D03_BAD + 1))
    else
        D03_C_CFG_SRC=${D03_C_CFG% *}
        D03_C_CFG_RO=${D03_C_CFG#* }
        if [ "$D03_C_CFG_SRC" != "$D03_BEETS_CONFIG_SOURCE" ]; then
            echo "  ❌ dormant CLI arm: $D03_BEETS_CONFIG_DEST comes from '$D03_C_CFG_SRC', expected '$D03_BEETS_CONFIG_SOURCE'"
            EXIT_CODE=1
            D03_BAD=$((D03_BAD + 1))
        fi
        if [ "$D03_C_CFG_RO" != "ro" ]; then
            echo "  ❌ dormant CLI arm: $D03_BEETS_CONFIG_DEST is declared $D03_C_CFG_RO, expected ro"
            EXIT_CODE=1
            D03_BAD=$((D03_BAD + 1))
        fi
    fi
    D03_C_MEDIA=$(printf '%s\n' "$D03_CLI_MOUNTS" | awk -v s="$D03_MEDIA_SOURCE" '$1==s {print $3}')
    if [ -z "$D03_C_MEDIA" ]; then
        echo "  ❌ the dormant CLI arm declares NO mount from $D03_MEDIA_SOURCE — D-05 cannot be asserted for it"
        EXIT_CODE=1
        D03_BAD=$((D03_BAD + 1))
    elif [ "$D03_C_MEDIA" != "ro" ]; then
        echo "  ❌ D-05 VIOLATED — the dormant CLI arm declares $D03_MEDIA_SOURCE as $D03_C_MEDIA, expected ro"
        EXIT_CODE=1
        D03_BAD=$((D03_BAD + 1))
    fi
    if [ "$D03_LOOKED" -eq 1 ] && [ "$D03_BAD" -eq 0 ] && [ "$D03_OVERRIDDEN" -eq 0 ]; then
        echo "  ✅ one config, both containers: $D03_BEETS_CONFIG_SOURCE -> $D03_BEETS_CONFIG_DEST :ro"
        echo "     runtime  ($D03_FLASK_CONTAINER, inspected): config :ro, $D03_MEDIA_SOURCE :ro"
        echo "     declared (dormant CLI arm, rendered):       config :ro, $D03_MEDIA_SOURCE :ro"
    fi
fi

# D-04 — NO `beet` INVOCATION MAY OPEN THE REAL LIBRARY. Added 2026-09-21 (plan 06-10).
# See the TENTH EXIT-CODE notice at the top of this file for what this added to the fatal path.
#
# WHAT IT ASSERTS, AND WHY BOTH FLAGS ARE REQUIRED RATHER THAN ONE. One library.db is mounted into
# two different beets versions (D-03 above): the LSIO image is 2.13.1 and beets-flask executes
# 2.12.0. A bare `beet` in the CLI arm would OPEN that database and MIGRATE ITS SCHEMA under
# 2.12.0's feet — Phase 1 measured a bare `beet config` running 11 migrations unasked. So every
# invocation intended for the CLI arm must carry BOTH:
#   * `-l <throwaway>`, pointing anywhere except /config/library.db; AND
#   * `-c <overlay>`, because `-l` ALONE DOES NOT REDIRECT `statefile:`. The statefile is a
#     SEPARATE pickle holding the incremental-import marks, it is not covered by `-l` at all, and
#     a throwaway import on a throwaway `-l` still writes the shared state.pickle. The overlay is
#     the only thing that redirects `library`, `statefile` AND `directory` together.
# `-l` alone is the plausible-looking half-fix, which is exactly why the assertion names statefile.
#
# ⚠️  WIDENED 2026-09-22 BY PLAN 06-16 (CR-01), AND THE REASON IS THE WHOLE POINT OF THE BLOCK.
# As shipped on 2026-09-21 this assertion MATCHED NOTHING AT ALL and printed a green tick over the
# empty set for the whole of Phase 6. Measured on the host's HEAD: raw 91, comment-stripped 35,
# invocation-shaped outside `*.md` ZERO. The cause is not subtle and is stated so it is not
# repeated — EVERY `beet` call this repository makes from a script is assembled from a VARIABLE
# (`"$BEET"`, `"$BEET_BIN"`, `"${BEET_BIN}"`), never from the literal token `beet`, so a scan
# looking for a literal `beet` word had no way to see a single one of them. Two things were wrong
# and fixing either alone would have been worse than useless:
#   * THE REMOTE PATTERN. `git grep -w -E 'beet'` is CASE SENSITIVE, so `$BEET_BIN` was never even
#     returned to be matched against. Widening the LOCAL regex alone would therefore have left the
#     executable count at zero and turned the new vacuity guard below into a permanent UNKNOWN.
#     A SECOND `-e` pattern is used rather than an alternation for the reason the next paragraph
#     gives: `-e 'x' -e 'y'` carries no `|` into the remote command string.
#   * THE LOCAL SHAPE TEST. A variable expansion in COMMAND POSITION is now an invocation shape.
#     It is anchored exactly like the literal branches — content start, after a shell separator,
#     or immediately inside an opening quote — AND it must be followed by a flag or a subcommand
#     word. Both halves are load-bearing: without the anchor, `[[ $BEET_EXEC_RC -eq 0 ]]` and
#     `"$BEETS_DB_COUNT"` are "invocations"; without the follower test, argument passing such as
#     `remote_exec "$prog" "$root" "$BEET" "$PY"` is an "invocation". Measured: the naive
#     whitespace-or-quote form matched 26 lines of which 18 run nothing. The follower test admits
#     a BARE `"$BEET" config` — it deliberately does NOT require a flag — so it cannot be accused
#     of only matching invocations that were already compliant.
# The literal-`beet` branches are KEPT, not replaced. They are what still catches a hand-written
# `beet import …` pasted out of the runbook, and they are what keeps the `*.md` baseline meaningful.
#
# SCOPE, AND THE TWO EXCLUSIONS, STATED RATHER THAN SILENT. The asserted set is every text file
# tracked under scripts/ and stacks/ at the host's HEAD, MINUS `*.md` and MINUS a NAMED, COUNTED
# and PINNED exemption register (see THE EXEMPTION REGISTER below). Documentation is excluded
# because two of this repo's `.md` lines are HISTORIC QUOTATIONS — beets.md records "the documented
# flow" as it was in Nov 2025, and rewriting a quotation to satisfy a grep falsifies the record
# this repo keeps deliberately. The exclusion is not a free pass: documentation hits are COUNTED
# against a pinned baseline (D04_DOC_BASELINE) and a change in that count is its own red, so a new
# copy-pasteable bare invocation cannot arrive in the runbook unseen.
#
# THE STRIP IS PROVEN TO BE DOING WORK, WHICH IS THE WHOLE REASON FOUR COUNTS ARE PRINTED. This
# repository has been bitten four separate times by a grep satisfied by prose ABOUT a thing rather
# than by the thing. A single number cannot distinguish "nothing matched" from "the pattern was
# wrong", so the raw hit count, the comment-stripped count, the invocation-shaped count and the
# exempt count are all reported. If raw and stripped are equal, the strip is not stripping and the
# result is suspect. AND — added 2026-09-22 by plan 06-16, because this is the failure that
# actually happened — if the EXECUTABLE invocation count is zero, that is UNKNOWN and fatal, not
# a pass. The 2026-09-21 block reported the executable count and then never tested it, which is
# how it printed a tick over an empty set for a month. A number that is printed but not asserted
# is not an assertion; it is a decoration. Every count printed on the `counts:` line below is now
# either asserted directly or pinned to a baseline whose movement is its own red.
#
# WHY IT READS THE HOST'S HEAD RATHER THAN THE WORKSTATION'S WORKING TREE. Same reason the drift
# block does: a dirty or stale checkout on the workstation must not be able to produce a false
# green or a false red, and the host runs what the host has. The consequence is stated plainly —
# a fix committed here is not asserted until it is pushed and pulled, which surfaces as a red
# naming the offending line, not as a silence.
#
# THE REMOTE PATTERN IS `git grep -w beet` AND CARRIES NO `|` ON PURPOSE. The obvious form,
# an anchored alternation, puts a literal pipe in the command string — and this file's greppable
# `timeout $REMOTE_TIMEOUT.*|` invariant matches on the LINE, so a pipe inside a regex reads to
# that grep exactly like an unguarded shell pipeline. Three pre-existing lines already trip it
# that way (two `sha256sum` stages inside a `pipefail`-headed string, and one `|| echo`); adding a
# fourth false positive would erode an invariant that is only worth having while it is clean.
# `-w` is also MEASURED-equivalent, not assumed: on the host's HEAD it returns 37 raw hits against
# the alternation's 30, and the invocation-shaped set is IDENTICAL (the same two lines).
#   ⚠️  2026-09-22 (plan 06-16): the `|`-free requirement is WHY the case-sensitivity fix is a
#   SECOND `-e` flag rather than `-E 'beet|BEET…'`. `git grep -e X -e Y` ORs its patterns with no
#   pipe character anywhere in the command string, so the invariant above is preserved untouched —
#   measured, not assumed: the count of lines matching that invariant is unchanged by this edit.
#   `-i` was considered and REJECTED: it would also fold `Beet`/`BeetS` prose in stacks/*.yaml
#   comments into the raw count for no gain, and `-w -E 'BEET[A-Z_]*'` is the narrower statement
#   of what is actually being looked for — a shell variable holding the beets binary.
#
# THE EXEMPTION REGISTER, AND ITS REASON IN FULL, BECAUSE AN UNEXPLAINED EXEMPTION IS WORSE THAN
# NONE. Five invocation-shaped executable lines are NOT asserted against the literal `-l`-and-`-c`
# rule. They are NAMED by `D04_EXEMPT_RE` (keyed on the file path AND the distinguishing overlay
# variable, so a DIFFERENT invocation added to either file does not inherit the exemption) and
# COUNTED against `D04_EXEMPT_BASELINE`; a move in that count is its own red that prints every
# exempt line. The five are the three `phase06-oracle.sh` lines carrying `$SCRATCH_OVERLAY` and
# the two `phase06-incremental-control.sh` lines carrying `$ROOT/overlay.yaml`. Three reasons,
# all of which have to hold:
#   1. EACH ONE PASSES A `-c` OVERLAY THAT REDIRECTS `library`, `statefile` AND `directory`
#      TOGETHER into a throwaway root. That is the STRONGER half of D-04's rule and the half `-l`
#      cannot achieve at all — `-l` redirects `library` and nothing else, which is exactly why the
#      contract paragraph at the top of this block names `statefile:` rather than assuming it.
#      These lines are not a weaker form of compliance; they satisfy the part that matters most.
#   2. ADDING A `-l` WOULD MAKE THEM WORSE, NOT BETTER. A `-l` naming a path OTHER than the
#      overlay's `library:` splits the throwaway state across two files, so the run's own state
#      stops being readable in one place; a `-l` naming the SAME path is a second source of truth
#      for one value, and the two drift the first time either is edited.
#   3. BOTH SCRIPTS ARE CLOSED INSTRUMENTS WHOSE PROOF RUNS ARE ALREADY RECORDED. Changing their
#      invocation flags would invalidate committed evidence that cannot be re-driven inside this
#      phase. The artifacts are named so the reason is checkable rather than asserted:
#      `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-11-oracle-run.txt` and
#      `.../artifacts/06-11-wrote-nothing.txt` for the oracle, and `.../06-20-incremental-driven.txt`
#      for the incremental control.
#   ⛔ THE EXEMPTION IS NOT A SKIP. The green line below NAMES the exempt count, so a green D-04
#   always states how many lines it did not assert over. A reader who never opens this comment
#   still cannot mistake 3 asserted lines for 8.
#
# AND THIS PARAGRAPH ITSELF MOVES THAT GREP'S COUNT, WHICH IS STATED RATHER THAN ROUNDED, the same
# convention the EXIT-CODE notices use: `grep -c 'timeout $REMOTE_TIMEOUT.*|'` goes 6 -> 8, because
# this block quotes the pattern literally TWICE — once in the paragraph above and once in this
# one. Measured before and after, not assumed. The real COMMAND lines are
# unchanged at 6, of which three are false positives that pre-date this edit (`:889`'s `|| echo`,
# and `:1194`/`:1195`, whose pipes sit inside a command string already headed by `set -o pipefail`).
# Do not reword this paragraph to flatter the grep, and do not "fix" the offset by deleting the
# quotes — count the command lines, not the matches.
#
# NO PIPE IN THE REMOTE STRING, and the matching is LOCAL. `git grep` exits 1 when it matches
# nothing, which is a legitimate PASS, so the status is captured and only >1 is a failure — and a
# `D04-BEGIN` sentinel is emitted FIRST so that "looked and found nothing" is distinguishable from
# "never ran". Without the sentinel those two produce identical empty output.
#   ⚠️  THE ORDER OF THE TWO STATUS TESTS IN THE REMOTE PROGRAM IS LOAD-BEARING (WR-10, fixed
#   2026-09-22 by plan 06-16). `timeout` reports a kill as 124, and 124 IS GREATER THAN 1, so
#   while `-gt 1 -> exit 4` was the only test a bound expiry arrived here as 4 and the operator was
#   told "'git grep' failed" — sent to debug a working tool instead of a wedged host. The block's
#   own dedicated 124 branch below was unreachable for this block, and the sentinel branch's
#   `-ne 124` special case was testing for something that could never happen. This file treats
#   "the bound expired" and "the tool failed" as DISTINCT conditions in nine places, and the TENTH
#   exit-code notice's condition I enumerates both by name, so collapsing them here made the
#   diagnosis wrong while the verdict stayed right — the worst shape a health check can take.
#   Test 124 FIRST, then `-gt 1`. `git grep` exiting 1 on no match remains a legitimate pass.
echo "D-04 — throwaway -l plus -c overlay on every beet invocation:"
D04_OVERRIDDEN=0
if [ "$D04_DOC_BASELINE" != "2" ]; then
    D04_OVERRIDDEN=1
    echo "  ⚠️  D04_DOC_BASELINE override in effect — this run cannot report D-04 green"
    EXIT_CODE=1
fi
if [ "$D04_REPO_ROOT" != "/mnt/fast/stacks" ]; then
    D04_OVERRIDDEN=1
    echo "  ⚠️  D04_REPO_ROOT override in effect — this run cannot report D-04 green"
    EXIT_CODE=1
fi
if [ "$D04_EXEMPT_BASELINE" != "5" ]; then
    D04_OVERRIDDEN=1
    echo "  ⚠️  D04_EXEMPT_BASELINE override in effect — this run cannot report D-04 green"
    EXIT_CODE=1
fi
# GC-17, 2026-09-22 (plan 06-26). Rendered once, quoted, and it is the RENDERED form that is
# interpolated into the scan's command string below. See the full note at the vendored-file drift
# block above for why, and for the bash dependency `printf '%q'` carries (GC-11).
D04_REPO_ROOT_Q=$(printf '%q' "$D04_REPO_ROOT")
D04_CMD="cd $D04_REPO_ROOT_Q || exit 3
echo D04-BEGIN
timeout $REMOTE_TIMEOUT git grep -n -I -w -E -e 'beet' -e 'BEET[A-Z_]*' HEAD -- scripts stacks
D04_RC=\$?
if [ \$D04_RC -eq 124 ]; then exit 124; fi
if [ \$D04_RC -gt 1 ]; then exit 4; fi
exit 0"
D04_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 "$D04_CMD")
D04_RC=$?   # ssh propagates the remote status — NO local pipe above
D04_SENTINEL=$(printf '%s\n' "$D04_OUT" | grep -c '^D04-BEGIN')
if [ "$D04_SENTINEL" -eq 0 ] && [ "$D04_RC" -ne 124 ]; then
    echo "  ⚠️  UNKNOWN — the D-04 scan produced no sentinel (ssh exit $D04_RC; 3 = no"
    echo "  /mnt/fast/stacks checkout, 4 = 'git grep' failed). Nothing was scanned. This is NOT"
    echo "  'no bare beet invocations'."
    EXIT_CODE=1
elif [ "$D04_RC" -eq 124 ]; then
    echo "  ⚠️  UNKNOWN — the D-04 scan exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  Nothing was scanned. This is NOT 'no bare beet invocations'."
    EXIT_CODE=1
elif [ "$D04_RC" -ne 0 ]; then
    echo "  ⚠️  UNKNOWN — could not run the D-04 scan (ssh exit $D04_RC)."
    echo "  Nothing was scanned. This is NOT 'no bare beet invocations'."
    EXIT_CODE=1
else
    D04_HITS=$(printf '%s\n' "$D04_OUT" | grep '^HEAD:')
    D04_RAW=$(printf '%s\n' "$D04_HITS" | grep -c '^HEAD:')
    # Comment strip: `#` for shell and YAML, `//` for anything C-like. Applied to the CONTENT, so
    # the `HEAD:<path>:<line>:` prefix that git grep prepends cannot be mistaken for content.
    D04_KEPT=$(printf '%s\n' "$D04_HITS" | grep -vE '^HEAD:[^:]*:[0-9]*:[[:space:]]*(#|//)')
    D04_STRIPPED=$(printf '%s\n' "$D04_KEPT" | grep -c '^HEAD:')
    # Invocation shape, on the content only: at the start of the content, after a shell separator,
    # or after a `docker` prefix (`docker exec … beet …`). A back-ticked mention in prose or a
    # quoted mention inside a Python string does NOT match, which is the narrowing that makes the
    # stripped count meaningful rather than alarming.
    # FOURTH BRANCH added 2026-09-22 (plan 06-16), ITS ANCHOR SET WIDENED 2026-09-22 (plan 06-23,
    # GC-16): a BEET-prefixed variable expansion in COMMAND POSITION — content start, immediately
    # inside an opening quote, after a shell separator, or after a `docker` prefix — FOLLOWED BY a
    # flag or a lowercase subcommand word. Both halves are STILL required; see the WIDENED
    # paragraph in the block comment for the 26-vs-8 measurement that shows why neither alone is
    # honest. If you ever touch the anchors again, KEEP THE FOLLOWER TEST: dropping it while
    # widening the anchor set is exactly how the executable count goes back to 26.
    #   ⚠️ WHY THE ASYMMETRY MATTERED, AND WHY IT SHIPPED WITH GC-03. The three literal-token
    #   branches above already anchored on separators and on `docker`; this one did not. So the
    #   same expansion after `&&`, or inside a `docker exec` line, was invocation-shaped and
    #   INVISIBLE to the scan — and GC-03 names precisely that as the silent route by which the
    #   ASSERTED set drops to zero without any counter leaving its pin. Fixing either alone leaves
    #   the route open. There was NO CURRENT INSTANCE of either shape in the tree, so this closed a
    #   latent blind spot rather than an active miss, and the widening is proven ADDITIVE by an
    #   unchanged count vector (invocation-shaped 10, executable 8, asserted 3, exempt 5,
    #   documentation 2) recorded in
    #   .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-23-d04-assert-vacuity.txt
    #   ⚠️ AND THE REVIEWER'S JUSTIFICATION FOR THIS FINDING WAS FALSE, kept here so it is not
    #   re-argued: it claimed the paragraph above promised separator anchoring and that the code
    #   did not deliver it. The paragraph said "content start, or immediately inside an opening
    #   quote", which is what the code did. There was no documentation mismatch — the gap was
    #   substantive, graded WARNING not BLOCKER, and these lines are the comment being brought
    #   FORWARD to the widened behaviour, not corrected backwards to the old one.
    D04_INV_RE='^HEAD:[^:]*:[0-9]*:[[:space:]]*(sudo[[:space:]]+)?beet[[:space:]]|[[:space:]](&&|;)[[:space:]]*beet[[:space:]]|docker[[:space:]][^`]*[[:space:]]beet[[:space:]]|(^HEAD:[^:]*:[0-9]*:[[:space:]]*(sudo[[:space:]]+)?|"|[[:space:]](&&|;)[[:space:]]*|docker[[:space:]][^`]*[[:space:]])\$\{?BEET[A-Z_]*\}?"?[[:space:]]+(-|[a-z])'
    # The NAMED exemption register. Keyed on the file path AND the distinguishing overlay variable,
    # so a different invocation added to either file does NOT inherit the exemption. Reason in full
    # in the block comment above; count pinned by D04_EXEMPT_BASELINE.
    D04_EXEMPT_RE='^HEAD:scripts/phase06-oracle\.sh:[0-9]*:.*\$SCRATCH_OVERLAY|^HEAD:scripts/phase06-incremental-control\.sh:[0-9]*:.*\$ROOT/overlay\.yaml'
    D04_INVOKE_ALL=$(printf '%s\n' "$D04_KEPT" | grep -E "$D04_INV_RE")
    D04_INVOKE_DOC=$(printf '%s\n' "$D04_INVOKE_ALL" | grep '\.md:')
    D04_INVOKE_EXE=$(printf '%s\n' "$D04_INVOKE_ALL" | grep -v '\.md:' | grep '^HEAD:')
    D04_INVOKE_EXEMPT=$(printf '%s\n' "$D04_INVOKE_EXE" | grep -E "$D04_EXEMPT_RE")
    D04_INVOKE_ASSERT=$(printf '%s\n' "$D04_INVOKE_EXE" | grep -vE "$D04_EXEMPT_RE" | grep '^HEAD:')
    D04_N_ALL=$(printf '%s\n' "$D04_INVOKE_ALL" | grep -c '^HEAD:')
    D04_N_DOC=$(printf '%s\n' "$D04_INVOKE_DOC" | grep -c '^HEAD:')
    D04_N_EXE=$(printf '%s\n' "$D04_INVOKE_EXE" | grep -c '^HEAD:')
    D04_N_EXEMPT=$(printf '%s\n' "$D04_INVOKE_EXEMPT" | grep -c '^HEAD:')
    D04_N_ASSERT=$(printf '%s\n' "$D04_INVOKE_ASSERT" | grep -c '^HEAD:')
    echo "  counts: raw=$D04_RAW  comment-stripped=$D04_STRIPPED  invocation-shaped=$D04_N_ALL  (executable $D04_N_EXE = asserted $D04_N_ASSERT + exempt $D04_N_EXEMPT, documentation $D04_N_DOC)"
    if [ "$D04_RAW" -eq 0 ]; then
        echo "  ⚠️  UNKNOWN — the raw scan matched NOTHING at all. This repository is known to"
        echo "  mention beets in many files, so a zero here means the pattern is wrong, not that"
        echo "  the tree is clean. Nothing is asserted."
        EXIT_CODE=1
    elif [ "$D04_RAW" -eq "$D04_STRIPPED" ]; then
        echo "  ⚠️  UNKNOWN — the comment strip removed NOTHING ($D04_RAW = $D04_STRIPPED), so it"
        echo "  is not doing its job and the narrowed count below cannot be trusted."
        EXIT_CODE=1
    elif [ "$D04_N_EXE" -eq 0 ]; then
        echo "  ⚠️  UNKNOWN — the invocation pattern matched NO executable line ($D04_N_EXE). Every"
        echo "  beet call this repo makes is built from a variable, so a zero here means the pattern"
        echo "  cannot SEE the invocations, not that none exist. This is NOT 'no bare beet"
        echo "  invocations'. Nothing is asserted."
        EXIT_CODE=1
    elif [ "$D04_N_ASSERT" -eq 0 ]; then
        # CONDITION P (plan 06-23, GC-03). Condition K one nesting level in: K refuses a zero
        # EXECUTABLE count, but the set the loop below actually iterates is executable MINUS
        # exempt. With every executable line exempt, K passes, both pins hold, the loop runs zero
        # times and the green line below would print `0 of N`. See the THIRTEENTH exit-code notice.
        echo "  ⚠️  UNKNOWN — every invocation-shaped executable line is EXEMPT ($D04_N_EXEMPT of"
        echo "  $D04_N_EXE). Nothing was asserted over, so the -l-and-c rule below was applied to an"
        echo "  EMPTY set and could not have failed. This is NOT 'no bare beet invocations'."
        echo "  Nothing is asserted."
        EXIT_CODE=1
    else
        D04_BAD=0
        while IFS= read -r d04_line; do
            [ -z "$d04_line" ] && continue
            d04_l=0; d04_c=0; d04_real=0
            case "$d04_line" in *" -l "*) d04_l=1 ;; esac
            case "$d04_line" in *" -c "*) d04_c=1 ;; esac
            case "$d04_line" in *" -l /config/library.db"*) d04_real=1 ;; esac
            if [ "$d04_l" -eq 0 ] || [ "$d04_c" -eq 0 ] || [ "$d04_real" -eq 1 ]; then
                echo "  ❌ beet invocation without a throwaway -l AND a -c overlay (statefile: is NOT redirected by -l alone):"
                echo "       $d04_line"
                EXIT_CODE=1
                D04_BAD=$((D04_BAD + 1))
            fi
        done <<< "$D04_INVOKE_ASSERT"
        if [ "$D04_N_EXEMPT" -ne "$D04_EXEMPT_BASELINE" ]; then
            echo "  ❌ exempt invocation count moved: $D04_N_EXEMPT, pinned baseline $D04_EXEMPT_BASELINE."
            echo "  An exemption that grows unseen is how a real violation gets waved through. Lines:"
            printf '%s\n' "$D04_INVOKE_EXEMPT" | sed 's/^/       /'
            EXIT_CODE=1
        fi
        if [ "$D04_N_DOC" -ne "$D04_DOC_BASELINE" ]; then
            echo "  ❌ documentation invocation count moved: $D04_N_DOC, pinned baseline $D04_DOC_BASELINE."
            echo "  A new copy-pasteable bare invocation in the runbook is a real footgun. Lines:"
            printf '%s\n' "$D04_INVOKE_DOC" | sed 's/^/       /'
            EXIT_CODE=1
        fi
        # `D04_N_ASSERT" -gt 0` is belt and braces over condition P's arm above (plan 06-23,
        # GC-03) and is kept because the tick's own text quotes `$D04_N_ASSERT of $D04_N_EXE`:
        # with it here, the tick and the number it prints cannot disagree, whatever future edit
        # is made to the ladder above.
        if [ "$D04_BAD" -eq 0 ] && [ "$D04_N_ASSERT" -gt 0 ] && [ "$D04_N_DOC" -eq "$D04_DOC_BASELINE" ] \
           && [ "$D04_N_EXEMPT" -eq "$D04_EXEMPT_BASELINE" ] && [ "$D04_OVERRIDDEN" -eq 0 ]; then
            echo "  ✅ no ASSERTED beet invocation opens the real library ($D04_N_ASSERT of $D04_N_EXE invocation-shaped lines outside *.md)"
            echo "     $D04_N_EXEMPT lines were NOT asserted over — the named exemption register at the pinned baseline ($D04_EXEMPT_BASELINE), see the block comment"
            echo "     documentation hits at the pinned baseline ($D04_N_DOC) — historic quotations, see the block comment"
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
#
# ── R3-01, 2026-09-23 (round-3 gap closure, plan 06-30) ───────────────────────────────────────────
# THE PATH CROSSES INTO THE CONTAINER AS A POSITIONAL PARAMETER, NOT AS COMMAND TEXT. The `sh -c`
# program below names no path at all: it reads "$1", and the rendered value arrives after the
# literal `sh` (which is $0 — without it the first real argument is eaten). This is the shape
# scripts/phase06-oracle.sh's remote_sh_c() uses, and the reason is the same one stated there:
# `printf '%q'` renders for a bash WORD, which is the one context it is correct for, and a value
# landing inside the TEXT of a single-quoted program can terminate that program's quoting.
#
# WHAT WAS HERE BEFORE, described by shape rather than pasted: a hand-escaped `\"` wrapper around
# the path variable, inside a single-quoted remote `sh -c`. That is the construction the GC-17
# prohibition block names explicitly, and it survived three hundred lines below that prohibition for
# a full gap-closure round while the same round's census sentence declared the class closed. The
# literal is deliberately NOT reproduced anywhere in this file, not even to disown it: a claim and
# its retraction are indistinguishable to grep, and a mechanical check for the retired shape has to
# be able to return zero.
#
# THE BOUND, STATED RATHER THAN DRAMATISED. EXTCONF_PATH is an operator-set environment knob with a
# safe default, not attacker-controlled input, and it is ADDITIVE — any non-default value already
# forces EXIT_CODE=1 at the override check above, so it can never produce a green tick. The
# injection consequence that motivated this edit is STATIC REASONING AND WAS NOT EXECUTED. What
# makes it worth fixing is not the exploit; it is that a documented-forbidden shape survived a round
# inside the file that documents it.
EXTCONF_CMD="set -o pipefail
timeout $REMOTE_TIMEOUT docker exec sabnzbd true >/dev/null 2>&1
_ec_rc=\$?
[ \$_ec_rc -eq 124 ] && exit 124
[ \$_ec_rc -ne 0 ] && exit 3
_ec=\$(timeout $REMOTE_TIMEOUT docker exec sabnzbd sh -c 'cat \"\$1\"' sh $EXTCONF_PATH_Q 2>/dev/null)
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
CONSUMERS_OVERRIDDEN=0
if [ "$CONSUMERS_SCRIPT" != "/mnt/fast/stacks/scripts/check-music-consumers.sh" ]; then
    CONSUMERS_OVERRIDDEN=1
fi
# GC-17, 2026-09-22 (plan 06-26). Rendered once, quoted, and it is the RENDERED form that is
# interpolated into the remote command string below. This knob names a FILE rather than a root, but
# the boundary and the defect are identical. See the full note at the vendored-file drift block
# above for why, and for the bash dependency `printf '%q'` carries (GC-11).
CONSUMERS_SCRIPT_Q=$(printf '%q' "$CONSUMERS_SCRIPT")
CONSUMERS_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 \
    "timeout $REMOTE_TIMEOUT bash $CONSUMERS_SCRIPT_Q 2>&1")
CONSUMERS_RC=$?   # ssh propagates the remote exit status — do NOT pipe before capturing this
# Strip ANSI colour separately. \x1b is a GNU sed extension and this script runs on macOS, so the
# ESC is spelled with bash's $'...' quoting instead.
CONSUMERS_OUT=$(printf '%s\n' "$CONSUMERS_OUT" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')

# ── GC-14, 2026-09-22 (round-2 gap closure, plan 06-26) ─────────────────────────────────────────
# WHY THE OVERRIDE NOTICE NOW APPEARS ON EVERY ARM AND NOT ONLY ON THE ONE THAT CAN GO GREEN.
# `CONSUMERS_OVERRIDDEN` used to be consulted in exactly ONE place — inside the `-eq 0` arm, where
# its job is to stop a TICK. Every other arm is non-green already, so it looked like there was
# nothing left to stop. There was: on those arms the override does not change the VERDICT, it
# changes what the verdict is ABOUT.
#   * the `-eq 0` arm needs the notice to stop a GREEN TICK over an arbitrary file;
#   * the `-eq 3` arm and the generic `else` need it to stop a WRONG DIAGNOSIS — the operator is
#     told "the estate is off target" / "the audit is broken" when what was actually measured is
#     an arbitrary file;
#   * the empty-output and 124 arms need it most bluntly of all, because their text NAMES THE
#     DEPLOYED PATH in its re-run advice, which under an override is a path nobody just ran.
# That is exactly the shape of WR-10 and WR-03, which this same wave fixed elsewhere in this file.
# THE VERDICTS ARE UNTOUCHED: every arm below already set EXIT_CODE=1 and still does, and the
# ADDITIVE CONTRACT is unchanged — an override may drive any arm and can never produce the tick.
# This is a DIAGNOSIS change only. Keep the notice a pure `echo`; the moment one of these guards
# touches EXIT_CODE or a count, "pending" and "measured red" start to collapse into each other,
# which is the distinction 06-DISPOSITIONS.md's WR-03 row exists to protect.
#
# Empty-output test first, deferring only to the bound — see the full argument on the freeze block
# above. The ordering and the one qualification are identical in all three blocks on purpose.
if [ -z "$CONSUMERS_OUT" ] && [ "$CONSUMERS_RC" -ne 124 ]; then
    # Unreachable host, or the script is not on the host at all. Absence of a failure signal is
    # NOT evidence of health — same precedent as the freeze block above.
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the audit produced no output"
    echo "  The consumers state is unknown, NOT green. Check the host, then re-run:"
    echo "  ssh root@172.16.1.159 'cd /mnt/fast/stacks && git pull --ff-only && bash scripts/check-music-consumers.sh'"
    if [ "$CONSUMERS_OVERRIDDEN" -eq 1 ]; then   # GC-14
        echo "  ⚠️  CONSUMERS_SCRIPT override in effect — ran: $CONSUMERS_SCRIPT (not the deployed"
        echo "  path). Read the re-run line above as the DEPLOYED audit, which is not what just"
        echo "  produced no output. This says nothing about 172.16.1.159 being unreachable."
    fi
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
    if [ "$CONSUMERS_OVERRIDDEN" -eq 1 ]; then   # GC-14
        echo "  ⚠️  CONSUMERS_SCRIPT override in effect — ran: $CONSUMERS_SCRIPT (not the deployed"
        echo "  path). What exceeded the bound was THAT file. Neither dockerd nor Music Assistant"
        echo "  has been implicated by this run."
    fi
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
        if [ "$CONSUMERS_OVERRIDDEN" -eq 1 ]; then   # GC-14
            echo "  ⚠️  CONSUMERS_SCRIPT override in effect — ran: $CONSUMERS_SCRIPT (not the"
            echo "  deployed path). The heading that could not be found is THAT file's, so this is"
            echo "  not evidence that the deployed audit's cross-file contract has moved."
        fi
        EXIT_CODE=1
    elif [ "$CONSUMERS_OVERRIDDEN" -eq 1 ]; then
        # ADDITIVE CONTRACT. An overridden CONSUMERS_SCRIPT may drive any arm of this fold-in, but
        # it may never produce the tick: the audit that answered was not the deployed one, so this
        # run says nothing about the estate. Same shape as DRIFT_ROOT_OVERRIDDEN / D03_OVERRIDDEN /
        # D04_OVERRIDDEN / EXTCONF_OVERRIDDEN. There is no success-producing override in this file.
        echo "⚠️  CONSUMERS_SCRIPT override in effect — this run cannot report the consumers green"
        echo "  ran: $CONSUMERS_SCRIPT (not the deployed path). Exit 0 from an overridden audit is"
        echo "  evidence about THAT file, not about the estate."
        echo "$SUMMARY" | sed 's/^/  /'
        EXIT_CODE=1
    else
        echo "✅ Both consumers see the library"
        echo "$SUMMARY" | sed 's/^/  /'
    fi
elif [ "$CONSUMERS_RC" -eq 3 ]; then
    # EXIT 3 = CONF-04 PENDING (WR-03, plan 06-17, 2026-09-22). NOT a broken audit and NOT green.
    #
    # check-music-consumers.sh reads the D-22 artist rows successfully and finds one or more of
    # them sitting at a RECORDED BASELINE rather than at target. Until 2026-09-22 that state
    # printed in yellow and exited 0, and this fold-in printed a tick over it. It then landed in
    # the generic `else` below for a few minutes of this plan — non-green, which was right, but
    # labelled `❌ BROKEN`, which was wrong: nothing is broken, the instrument worked, the estate
    # is not where CONF-04 needs it to be. Same verdict, correct label.
    #
    # ⚠ EXIT_CODE=1 HERE IS THE LOAD-BEARING HALF, AND IT IS DELIBERATE. This script exits 0 when
    #   healthy and non-zero on any violation; a REQUIREMENT that is measured and open is not
    #   healthy. So CONF-04 pending makes the whole health check non-zero for as long as it is
    #   open — that is not a bug to be tuned out, it is what makes a post-Phase-7 REGRESSION back
    #   to the baseline detectable by tooling rather than only by a human reading yellow text.
    #   Do not add an override: there is no success-producing knob anywhere in this file.
    #
    #   WHAT CLEARS IT — TWO OWNERS, NOT ONE. Corrected 2026-09-24 (plan 06-44, round 5). This
    #   paragraph used to end "It clears when ROADMAP entry criterion E6 discharges the Jellyfin
    #   half, and on nothing else", which was true and under-specified: E6 owns TWO measurements
    #   and the audit's two pending counts are waiting on DIFFERENT ones of them. The audit's own
    #   exit-3 banner now says the same thing in the same words, and the two accounts must be
    #   corrected together or they drift (the GC-04 stale-citation class).
    #     * THE JELLYFIN COUNT. Its other candidate route — a file mtime change making the
    #       Default-mode refresh re-probe — was DRIVEN on 2026-09-24 inside a ZFS snapshot fence
    #       (plan 06-41) and MEASURED NOT TO DISCHARGE IT: all three pinned rows came back at
    #       their 2026-09-20 baseline, the 1,244-row census delta was empty, and
    #       PreferNonstandardArtistsTag re-read `true` afterwards, so the refresh ran and reached
    #       the items and the prober still did not re-read ARTISTS. See
    #       .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-42-conf04-reprobe-after.txt
    #       for the after-state and .../06-43-conf04-verdict.txt for the computed `BRANCH: B`.
    #       The one remaining route is a Phase 7 write or import, and that half is CARRIED to E6
    #       under the explicit operator override recorded in 06-43 SECTION P. AN OVERRIDE IS AN
    #       ARGUED, AUDITABLE CARRY OF AN OPEN REQUIREMENT — IT IS NOT A CLOSE, and nothing here
    #       may be read as ticking CONF-04.
    #     * THE MUSIC ASSISTANT COUNT. It is waiting on E6's SECOND measurement — whether a
    #       second >=4-artist track yields four artists in MA or three, the only thing that
    #       separates "MA caps the list at 3" from "Twista specifically failed to map". Round 5
    #       never had that in scope and produced no evidence bearing on it.
    #   Neither half discharges the other and the two counts are NEVER summed into one CONF-04
    #   answer. The audit exits 3 while EITHER is non-zero, which is why it would have exited 3
    #   even on a fully successful Jellyfin re-probe — so this arm firing is not, by itself,
    #   evidence about which half is open. Read the two counts in the summary below.
    #
    # The anchor guard is applied exactly as the `-eq 0` arm applies it. A renumbered `📊 6.`
    # heading must not be able to hide behind this new arm — an audit whose summary cannot be
    # read is UNKNOWN even when its exit status is one we understand.
    SUMMARY=$(echo "$CONSUMERS_OUT" | sed -n '/^📊 6\. Summary/,$p' \
              | grep -E 'MA version|artist rows|FAILURES total')
    if [ -z "$SUMMARY" ]; then
        echo "⚠️  UNKNOWN — the audit exited 3 but its '📊 6. Summary' block was not found."
        echo "  The section heading this fold-in anchors on has changed, so the pending counts"
        echo "  were not actually read. State is UNKNOWN, not merely pending, and not green."
        if [ "$CONSUMERS_OVERRIDDEN" -eq 1 ]; then   # GC-14
            echo "  ⚠️  CONSUMERS_SCRIPT override in effect — ran: $CONSUMERS_SCRIPT (not the"
            echo "  deployed path). The heading that could not be found is THAT file's, so this is"
            echo "  not evidence that the deployed audit's cross-file contract has moved."
        fi
        EXIT_CODE=1
    else
        echo "⚠️  CONF-04 MEASURED AND OPEN — artist rows at baseline, not at target (exit 3)"
        echo "  This is NOT an audit failure and NOT a pass. The Jellyfin and MA counts belong to"
        echo "  TWO DIFFERENT measurements inside ROADMAP entry criterion E6 and are never summed"
        echo "  into one CONF-04 answer: the Jellyfin half is carried to E6 under the recorded"
        echo "  2026-09-24 override after the mtime route was driven and measured not to discharge"
        echo "  it, and the MA half awaits E6's second, >=4-artist measurement. A carry is not a"
        echo "  close — CONF-04 stays open. The audit's own words:"
        # BOUNDED range. The end pattern is emitted by the same exit-3 block that produces status
        # 3, so it exists whenever this arm is reached — but a sed range whose end never matches
        # runs to EOF, so the `1,8p` cap is the guard rather than a trust in the end pattern.
        # (`sed -n '1,8p'` is used rather than `head -8`: `head` closes the pipe and the upstream
        # sed takes a SIGPIPE, which is the 141-propagation shape this phase has been bitten by.)
        echo "$CONSUMERS_OUT" | sed -n '/CONF-04 IS NOT CLOSED/,/Discharges on ROADMAP/p' \
            | sed -n '1,8p' | sed 's/^ */    /'
        echo "  Summary:"
        echo "$SUMMARY" | sed 's/^/    /'
        if [ "$CONSUMERS_OVERRIDDEN" -eq 1 ]; then   # GC-14
            echo "  ⚠️  CONSUMERS_SCRIPT override in effect — ran: $CONSUMERS_SCRIPT (not the"
            echo "  deployed path). Exit 3 from an overridden audit is evidence about THAT file,"
            echo "  not about the estate. CONF-04's state has NOT been measured by this run."
        fi
        EXIT_CODE=1
    fi
else
    echo "❌ BROKEN (check-music-consumers.sh exit $CONSUMERS_RC)"
    echo "  Failed assertions:"
    echo "$CONSUMERS_OUT" | grep '❌' | sed 's/^ */    /'
    echo "  Summary:"
    echo "$CONSUMERS_OUT" | sed -n '/^📊 6\. Summary/,$p' | sed 's/^/  /'
    if [ "$CONSUMERS_OVERRIDDEN" -eq 1 ]; then   # GC-14
        echo "  ⚠️  CONSUMERS_SCRIPT override in effect — ran: $CONSUMERS_SCRIPT (not the deployed"
        echo "  path). A non-zero exit from an overridden audit is evidence about THAT file, not"
        echo "  about the estate. Nothing here says the deployed audit is broken."
    fi
    EXIT_CODE=1
fi

# ── MUSIC IMPORT SWEEP — criterion 7 / IMPT-02 (plan 07-03, D-25) ────────────────────────────────
#
# WHAT AND WHY. scripts/check-music-import.sh asserts ZERO of the three criterion-7 damage classes
# over what beets imported: `.N`-suffix path collisions (DB rows and the on-disk files beside
# them), an empty mb_albumid on a non-DJ album item, and track count vs tracktotal per album-disc.
# It reads library.db READ-ONLY (Python sqlite, `mode=ro`, inside beets-flask) and makes no beets
# CLI invocation. Host-resident on LXC 100 because that is where the container is; it lands there
# by `git pull` into /mnt/fast/stacks, like the consumers audit above.
#
# ⚠️ UNKNOWN BY DESIGN UNTIL THE FIRST PILOT IMPORT. The real library holds 0 items, and the sweep
# refuses a vacuous green: an empty library, or ANY class with zero checkable rows, is its exit 3.
# That is the vacuity guard working, not a fault — and it is NEVER folded into green here.
#
# THE SHAPE IS COPIED FROM THE CONSUMERS BLOCK ABOVE: its own knob, the `_Q` render, the ssh status
# captured on the very next line with NO local pipe before it, the ANSI strip on its own line, the
# arms in the house S1 order (empty-not-124 → 124 → 0 → 3 → else), the `📊 N. Summary` anchor guard
# (CONVENTIONS §11), and the GC-14 override notice on every non-green arm. The remote string holds
# no pipe, so it needs no `set -o pipefail`.
echo -n "Music import sweep: "
IMPORT_SWEEP_OVERRIDDEN=0
if [ "$IMPORT_SWEEP_SCRIPT" != "/mnt/fast/stacks/scripts/check-music-import.sh" ]; then
    IMPORT_SWEEP_OVERRIDDEN=1
fi
IMPORT_SWEEP_SCRIPT_Q=$(printf '%q' "$IMPORT_SWEEP_SCRIPT")
IMPORT_SWEEP_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 \
    "timeout $REMOTE_TIMEOUT bash $IMPORT_SWEEP_SCRIPT_Q 2>&1")
IMPORT_SWEEP_RC=$?   # ssh propagates the remote exit status — do NOT pipe before capturing this
IMPORT_SWEEP_OUT=$(printf '%s\n' "$IMPORT_SWEEP_OUT" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')
if [ -z "$IMPORT_SWEEP_OUT" ] && [ "$IMPORT_SWEEP_RC" -ne 124 ]; then
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the import sweep produced no output"
    echo "  The criterion-7 state is unknown, NOT green. Check the host, then re-run:"
    echo "  ssh root@172.16.1.159 'cd /mnt/fast/stacks && git pull --ff-only && bash scripts/check-music-import.sh'"
    if [ "$IMPORT_SWEEP_OVERRIDDEN" -eq 1 ]; then   # GC-14
        echo "  ⚠️  IMPORT_SWEEP_SCRIPT override in effect — ran: $IMPORT_SWEEP_SCRIPT (not the"
        echo "  deployed path). Read the re-run line above as the DEPLOYED sweep, which is not what"
        echo "  just produced no output. This says nothing about 172.16.1.159 being unreachable."
    fi
    EXIT_CODE=1
elif [ "$IMPORT_SWEEP_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — the import sweep exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  This is NOT a clean sweep. Nothing was measured — the command never returned. A wedged"
    echo "  dockerd is the usual cause (read /proc/pressure/io on atlantis 172.16.1.158). Re-run with"
    echo "  a larger budget before concluding anything: REMOTE_TIMEOUT=300 bash scripts/quick-health-check.sh"
    if [ "$IMPORT_SWEEP_OVERRIDDEN" -eq 1 ]; then   # GC-14
        echo "  ⚠️  IMPORT_SWEEP_SCRIPT override in effect — ran: $IMPORT_SWEEP_SCRIPT (not the"
        echo "  deployed path). What exceeded the bound was THAT file; dockerd is not implicated."
    fi
    EXIT_CODE=1
elif [ "$IMPORT_SWEEP_RC" -eq 0 ]; then
    SUMMARY=$(echo "$IMPORT_SWEEP_OUT" | sed -n '/^📊 5\. Summary/,$p' \
              | grep -E 'items read|FINDINGS total')
    if [ -z "$SUMMARY" ]; then
        echo "⚠️  UNKNOWN — the import sweep exited 0 but its '📊 5. Summary' block was not found."
        echo "  The section heading this fold-in anchors on has changed, so nothing here was"
        echo "  actually read. State is UNKNOWN, not green. See check-music-import.sh's summary."
        if [ "$IMPORT_SWEEP_OVERRIDDEN" -eq 1 ]; then   # GC-14
            echo "  ⚠️  IMPORT_SWEEP_SCRIPT override in effect — ran: $IMPORT_SWEEP_SCRIPT (not the"
            echo "  deployed path). The heading that could not be found is THAT file's."
        fi
        EXIT_CODE=1
    elif [ "$IMPORT_SWEEP_OVERRIDDEN" -eq 1 ]; then
        # ADDITIVE CONTRACT. An overridden IMPORT_SWEEP_SCRIPT may drive any arm but never the tick.
        echo "⚠️  IMPORT_SWEEP_SCRIPT override in effect — this run cannot report the sweep green"
        echo "  ran: $IMPORT_SWEEP_SCRIPT (not the deployed path). Exit 0 from an overridden sweep is"
        echo "  evidence about THAT file, not about the library."
        echo "$SUMMARY" | sed 's/^/  /'
        EXIT_CODE=1
    else
        echo "✅ No criterion-7 damage in what beets imported"
        echo "$SUMMARY" | sed 's/^/  /'
    fi
elif [ "$IMPORT_SWEEP_RC" -eq 3 ]; then
    # EXIT 3 = the sweep COULD NOT LOOK, or found NOTHING TO CHECK. Not a finding, not green.
    # Until the first pilot import this is the expected arm (0 items). Its UNKNOWN reasons are
    # printed so the reader can tell "container down" from "library empty" without re-running.
    echo "⚠️  UNKNOWN — the sweep could not look or found nothing to check (exit 3)"
    echo "  NOT clean: a zero from a sweep that checked nothing means nothing. Its reasons:"
    echo "$IMPORT_SWEEP_OUT" | grep 'UNKNOWN reason:' | sed 's/^ */    /'
    echo "  Summary:"
    echo "$IMPORT_SWEEP_OUT" | sed -n '/^📊 5\. Summary/,$p' \
        | grep -E 'items read|checkable rows per class|FINDINGS total' | sed 's/^ */    /'
    if [ "$IMPORT_SWEEP_OVERRIDDEN" -eq 1 ]; then   # GC-14
        echo "  ⚠️  IMPORT_SWEEP_SCRIPT override in effect — ran: $IMPORT_SWEEP_SCRIPT (not the"
        echo "  deployed path). Exit 3 from an overridden sweep says nothing about the library."
    fi
    EXIT_CODE=1
else
    echo "❌ CRITERION-7 FINDINGS OR A BROKEN SWEEP (check-music-import.sh exit $IMPORT_SWEEP_RC)"
    echo "  Findings:"
    echo "$IMPORT_SWEEP_OUT" | grep '❌' | sed 's/^ */    /'
    echo "  Summary:"
    echo "$IMPORT_SWEEP_OUT" | sed -n '/^📊 5\. Summary/,$p' | sed 's/^/  /'
    if [ "$IMPORT_SWEEP_OVERRIDDEN" -eq 1 ]; then   # GC-14
        echo "  ⚠️  IMPORT_SWEEP_SCRIPT override in effect — ran: $IMPORT_SWEEP_SCRIPT (not the"
        echo "  deployed path). A non-zero exit from an overridden sweep is evidence about THAT file,"
        echo "  not about the library."
    fi
    EXIT_CODE=1
fi

# ── LIBRARY UNDERSCORE-DIRECTORY GUARD — ROADMAP Phase 5 criterion 4 (D-22) ──────────────────────
#
# WHAT AND WHY. Zero directories whose basename begins with `_` may exist anywhere under
# /mnt/tank/media/Music. Music Assistant silently ignores underscore-prefixed folders and Jellyfin
# does not, so a staging-style name leaking into the library makes the two consumers diverge BY
# DESIGN — and neither of them reports an error. There is no symptom to notice; this assertion IS
# the symptom. The staging tree under tank/downloads uses exactly those names on purpose
# (_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}), which is precisely why a leak
# is plausible rather than theoretical.
#
# THE SHAPE IS COPIED FROM THE CONTAINER-COUNT BLOCK ABOVE (:796-839), not its content. Both parts
# of that block's two-part fix are present and BOTH ARE NECESSARY:
#   1. `set -o pipefail` INSIDE THE REMOTE COMMAND STRING. `timeout T find … | wc -l` signals only
#      the FIRST stage; without pipefail `wc -l` reads the empty stream, prints `0` and exits 0, so
#      a killed find is indistinguishable from "there are none" — a bound expiry laundered into
#      exactly the answer this block is supposed to prove.
#   2. THE ssh STATUS CAPTURED ON THE VERY NEXT LINE, WITH NO LOCAL PIPE IN FRONT OF IT.
#      `VAR=$(ssh ... | tr -d ' ')` makes `$?` the tr's status, and `${PIPESTATUS[0]}` DOES NOT
#      rescue it — an assignment is a simple command, not a pipeline. The whitespace strip happens
#      on its own line, AFTER the status has been taken. Do not fold it back into the assignment.
#
# THREE VERDICTS, NEVER TWO — could-not-look / there-are-none / BROKEN. The could-not-look verdict
# has two arms (124 split out ahead of everything else, then any other non-zero or a non-integer
# answer) because this file's doctrine is that a bound expiry and a broken command are worth
# distinguishing in the message even though both mean "nothing was counted".
#
# ⚠️ THE READ TARGETS ATLANTIS (172.16.1.158), NOT LXC 100. It is the only host that can see the
# library tree authoritatively — a container-side listing shows LXC 100's sparse-idmap view, which
# is how phase 1 lost time to a phantom 65534. The WR-10 gate at the top of this file probes
# 172.16.1.159 and therefore does NOT cover this block, so ssh 255 is handled here as its own named
# UNKNOWN. Host and path are overridable, and either override forces a non-green run — the
# DASH_HOST / EXTCONF_HOST convention, reused rather than a second convention invented.
#
# ⛔ DO NOT ADD A `tank/downloads` OWNERSHIP ASSERTION HERE (phase 5 D-25). It is the obvious next
# thought while reading this block and it is forbidden: the download client keeps writing as uid
# 3000 at roughly one job per 72 seconds, so an "everything is 568:568" check would go red on the
# next download and train everyone to ignore the whole file. D-24's tree-wide chown is a one-time,
# `zfs diff`-verified sweep whose measurement and date are the deliverable — not a standing check.
#
# DRIVEN NEGATIVE CONTROL, 2026-09-18 (plan 05-02). The true count is zero, which makes the green
# path the default and would otherwise leave this an assertion nobody has seen fail. So it was
# driven: `mkdir /mnt/tank/media/Music/_probe` from ATLANTIS AS REAL ROOT — the sanctioned route,
# because phase 1's D-20 says no container holds rw on the library until phase 6 — and this block
# went RED, printing the count 1 and exiting the script 1. `rmdir` removed the probe and the block
# went GREEN again in the same session, with an EXIT trap guaranteeing removal and a follow-up find
# asserting absence. No chmod was attempted: mkdir and rmdir work on tank, chmod fails EPERM even
# as real root. Safe to do because jellyfin's real-time monitoring and metadata savers are off for
# the Music library (phase 1, 01-06), so an empty directory present for seconds writes nothing.
# Recorded here, in the VENDORED_DRIFT_PROMOTED style, because an instrument that has only ever
# been observed passing has not been shown to distinguish anything.
MUSIC_UNDERSCORE_HOST="${MUSIC_UNDERSCORE_HOST:-root@172.16.1.158}"
MUSIC_UNDERSCORE_ROOT="${MUSIC_UNDERSCORE_ROOT:-/mnt/tank/media/Music}"
# R3-01, 2026-09-23 (plan 06-30). TWO remote sites read this knob — the counting scan and the
# offending-paths listing — which is precisely why the rendering is sited here and not at either of
# them. Raw, an override containing a space word-split on the REMOTE shell; usually that failed
# closed into the could-not-look arm below, but where both split words named real directories
# `find` exited 0 and the count silently became a UNION OF TWO SCANS reported as one number.
MUSIC_UNDERSCORE_ROOT_Q=$(printf '%q' "$MUSIC_UNDERSCORE_ROOT")
if [ "$MUSIC_UNDERSCORE_HOST" != "root@172.16.1.158" ]; then
    echo "⚠️  MUSIC_UNDERSCORE_HOST override in effect — this run cannot report the library guard green"
    EXIT_CODE=1
fi
if [ "$MUSIC_UNDERSCORE_ROOT" != "/mnt/tank/media/Music" ]; then
    echo "⚠️  MUSIC_UNDERSCORE_ROOT override in effect — this run cannot report the library guard green"
    EXIT_CODE=1
fi
echo -n "Library underscore-dir guard: "
UNDERSCORE_OUT=$(ssh -n $SSH_OPTS "$MUSIC_UNDERSCORE_HOST" "set -o pipefail; timeout $REMOTE_TIMEOUT find $MUSIC_UNDERSCORE_ROOT_Q -type d -name '_*' | wc -l")
UNDERSCORE_RC=$?   # ssh propagates the remote status — NO local pipe above, see the note above
UNDERSCORE_COUNT=$(printf '%s' "$UNDERSCORE_OUT" | tr -d '[:space:]')
if [ "$UNDERSCORE_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — the library scan exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  NOTHING WAS COUNTED. This is NOT 'zero underscore directories under the library'."
    echo "  Re-run with a wider bound before believing anything about criterion 4:"
    echo "    REMOTE_TIMEOUT=300 bash scripts/quick-health-check.sh"
    EXIT_CODE=1
elif [ "$UNDERSCORE_RC" -ne 0 ] || ! echo "$UNDERSCORE_COUNT" | grep -qE '^[0-9]+$'; then
    echo "⚠️  UNKNOWN — could not scan $MUSIC_UNDERSCORE_ROOT on $MUSIC_UNDERSCORE_HOST"
    echo "  (ssh exit $UNDERSCORE_RC, output '$UNDERSCORE_COUNT')."
    echo "  NOTHING WAS COUNTED. This is NOT 'zero underscore directories under the library'."
    echo "  Exit 255 means the ssh to atlantis failed and find never ran — atlantis is the only"
    echo "  host that can answer this; LXC 100's view of the tree is an idmapped lie."
    echo "  A non-zero find status usually means the dataset is not mounted at that path."
    EXIT_CODE=1
elif [ "$UNDERSCORE_COUNT" -gt 0 ]; then
    echo "❌ $UNDERSCORE_COUNT '_'-prefixed director(y|ies) under $MUSIC_UNDERSCORE_ROOT"
    echo "  This IS a measurement, unlike the two branches above. ROADMAP phase 5 criterion 4 is"
    echo "  violated: Music Assistant will silently ignore each of these and Jellyfin will not, so"
    echo "  the two consumers now disagree about the library with no error on either side."
    echo "  Offending paths (from atlantis, read-only):"
    # Captured into a variable and printed on the NEXT line rather than piped inline. The pipe
    # would be LOCAL and therefore harmless, but `grep -n 'timeout \$REMOTE_TIMEOUT.*|'` over this
    # file is the house rule's own instrument (:444-453) and a line that needs a reader to work out
    # which side of the quotes the pipe is on costs more than the variable does. This runs only on
    # the already-red path, so its own failure cannot turn a green run red.
    UNDERSCORE_PATHS=$(ssh -n $SSH_OPTS "$MUSIC_UNDERSCORE_HOST" "timeout $REMOTE_TIMEOUT find $MUSIC_UNDERSCORE_ROOT_Q -type d -name '_*'")
    printf '%s\n' "$UNDERSCORE_PATHS" | sed 's/^/    /'
    EXIT_CODE=1
else
    echo "✅ No '_'-prefixed directories under $MUSIC_UNDERSCORE_ROOT"
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

# Image drift (quick task 260918-c12). Host-resident on LXC 100 for the plainest of reasons: it
# needs the docker daemon AND the repo checkout at /mnt/fast/stacks, and neither exists on this
# workstation. It also needs bash >= 4 for associative arrays; macOS ships 3.2, so the script
# guards on BASH_VERSINFO and exits 2 there — an ENVIRONMENT error, never a failed assertion. It
# lands on the host by `git pull` into /mnt/fast/stacks; there is no copy step to remember.
#
# THIS BLOCK IS THE FOURTH FOLD-IN AND IT IS SHAPED EXACTLY LIKE THE THREE ABOVE ON PURPOSE. That
# shape encodes four separate lessons this estate has already paid for, and each is load-bearing:
#   - `ssh -n` with `RC=$?` ON THE VERY NEXT LINE and NO PIPE before the capture. A pipe launders
#     124 into whatever the last stage returns (WR-09's subtle half), and `-n` stops a nested ssh
#     eating this script's stdin.
#   - the ANSI strip uses bash's $'\033' quoting, NOT `\x1b`, which is a GNU sed extension this
#     script cannot use because it runs on macOS.
#   - THE EMPTY-OUTPUT TEST COMES FIRST, deferring only to the bound. A zero-byte or absent script
#     exits 0, so branching on RC first would report a truncated check as GREEN.
#   - RC 124 is its own condition, distinct from a failed assertion: nothing was measured.
#
# WHAT IS FATAL HERE AND WHAT IS NOT — THE LOAD-BEARING JUDGEMENT OF THIS BLOCK:
#   FATAL: the measurement could not be TAKEN (host unreachable, empty output, 124, the summary
#          anchor missing), and any fatal finding the check itself reports — which is its
#          could-not-look count and its unresolvable-count/name-set assertion.
#   NOT FATAL: THE IMAGE DRIFT COUNT ITSELF. See IMAGE_DRIFT_PROMOTED near the top of this file for
#          the full argument; the short version is that v1 is alert-only, 14 containers are drifted
#          today, and nothing in this repository can clear that — so asserting it would make this
#          script permanently red on arrival. That is the 01-09 trap.
#
# HOW THE TWO ARE TOLD APART, because check-drift.sh EXITS 1 ON DRIFT ALONE and a naive
# `RC -eq 0` test would therefore send every ordinary run down the ❌ branch: its summary counts
# FATAL findings in `FAILURES total` and keeps the drift count on its OWN line, deliberately
# excluded from that total. So a non-zero exit carrying `FAILURES total: 0` AND `could-not-look: 0`
# means "drift exists, nothing is broken". That split is a CROSS-FILE CONTRACT and check-drift.sh
# says so at its own summary block; do not fold the drift count into FAILURES there without
# changing this.
# THE PRESENCE TEST IN THE REMOTE STRING IS NOT DECORATION — IT WAS ADDED AFTER THIS BLOCK WAS
# DRIVEN AGAINST A HOST THAT DID NOT YET HAVE THE SCRIPT, AND GAVE A CONFIDENT WRONG ANSWER.
# `bash <missing file>` writes "No such file or directory" to stderr, which `2>&1` captures — so
# the output is NOT empty, the empty-output test does not fire, and the run fell through to the
# summary-anchor branch and reported "the section heading has changed". Red, exit 1, and a
# diagnosis pointing at a heading nobody had touched. That is precisely the failure mode WR-10
# condemns at the top of this file: a confident wrong diagnosis rather than an honest UNKNOWN.
# The three older fold-ins escape it only because their scripts have been on the host for months.
#
# `exit 7` is chosen because check-drift.sh itself uses 0, 1 and 2 (2 = usage or environment
# error), so 7 cannot collide with anything the check reports. No pipe in the string, so the
# REMOTE_TIMEOUT bound is not laundered, and `bash -s` is not used — this repo forbids it by name.
echo -n "Container image drift: "
IMAGEDRIFT_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 \
    "[ -r /mnt/fast/stacks/scripts/check-drift.sh ] || exit 7; timeout $REMOTE_TIMEOUT bash /mnt/fast/stacks/scripts/check-drift.sh 2>&1")
IMAGEDRIFT_RC=$?   # ssh propagates the remote exit status — do NOT pipe before capturing this
IMAGEDRIFT_OUT=$(printf '%s\n' "$IMAGEDRIFT_OUT" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')

if [ "$IMAGEDRIFT_RC" -eq 7 ]; then
    echo "⚠️  UNKNOWN — /mnt/fast/stacks/scripts/check-drift.sh is NOT ON THE HOST."
    echo "  Not a fault in the estate and not drift: the check simply has not been pulled yet. It"
    echo "  lands by git, like every other script here — there is no copy step:"
    echo "    ssh root@172.16.1.159 'cd /mnt/fast/stacks && git pull --ff-only'"
    echo "  Image drift state is UNKNOWN until then, which is why this is red rather than skipped."
    EXIT_CODE=1
elif [ -z "$IMAGEDRIFT_OUT" ] && [ "$IMAGEDRIFT_RC" -ne 124 ]; then
    # Unreachable host, or the script is not on the host at all — the latter is the likely one for
    # a while, because check-drift.sh only reaches /mnt/fast/stacks on the next `git pull`.
    # Absence of a failure signal is NOT evidence of health. PROVEN REACHABLE, not assumed: driven
    # by moving the host-side script aside and restoring it under a sha256 check, the same device
    # plans 02.1-10 and 02.1-13 used.
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the drift check produced no output"
    echo "  Image drift state is unknown, NOT green — and 'no output' most often means the script"
    echo "  is simply not on the host yet. Pull, then re-run:"
    echo "  ssh root@172.16.1.159 'cd /mnt/fast/stacks && git pull --ff-only && bash scripts/check-drift.sh'"
    EXIT_CODE=1
elif [ "$IMAGEDRIFT_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — the remote drift check exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  This is NOT a failed assertion and NOT drift. Nothing was measured."
    echo "  This check runs 'docker compose config' once per distinct compose project (24 of them),"
    echo "  so it is the most docker-dependent block here — a wedged dockerd stops it dead. Confirm"
    echo "  on atlantis (172.16.1.158): /proc/pressure/io 'full' near 100% WITH AN IDLE CPU."
    echo "    cat /proc/pressure/io; uptime"
    echo "  A slow-but-healthy estate is the other possibility — re-run with a larger budget:"
    echo "    REMOTE_TIMEOUT=300 bash scripts/quick-health-check.sh"
    EXIT_CODE=1
else
    # The summary anchor. check-drift.sh says "KEEP THIS HEADING LITERAL AND NEVER RENUMBER IT
    # SILENTLY" — grep that file for KEEP THIS HEADING LITERAL, one hit. A documented coupling with
    # no detector is a coupling that will break, and it breaks on the branch that still prints a
    # tick, so an empty selection is UNKNOWN and fatal rather than a quiet blank.
    IMAGEDRIFT_SUMMARY=$(echo "$IMAGEDRIFT_OUT" | sed -n '/^📊 Summary/,$p' \
              | grep -E 'image drift|unresolvable|unhealthy|created|commits behind|could-not-look|FAILURES total')
    # Pull the discriminators out of the summary rather than trusting the exit code alone.
    #
    # `grep -o '^[0-9][0-9]*'` AND NOT `tr -dc '0-9'`. THE DIFFERENCE IS NOT COSMETIC AND IT WAS
    # CAUGHT BY DRIVING THE GREEN PATH, NOT BY READING IT. Every one of these lines carries
    # explanatory prose after the number, and that prose contains digits:
    #     image drift:        14  (REPORTED, not asserted — v1 is ALERT-ONLY, D-01)
    # `tr -dc '0-9'` over that keeps the 1 from "v1" and the 01 from "D-01" and yields 14101. The
    # first run of this block printed "✅ Measured — 14101 drifted". It was still GREEN and still
    # correct about being green, which is what makes the class of bug worth a comment: a mangled
    # number on the reassuring path is exactly the kind of thing nobody re-reads.
    #
    # Anchoring at ^ keeps the UNKNOWN behaviour that matters: a counter reading UNKNOWN yields the
    # EMPTY STRING, not a plausible 0, and empty is treated as fatal below rather than as "nothing
    # wrong". Same reasoning as avail_bytes() in check-jellyfin-transcode.sh — "could not look" and
    # "it is zero" are different answers and must not share a rendering.
    IMAGEDRIFT_FAILURES=$(echo "$IMAGEDRIFT_SUMMARY" | grep 'FAILURES total:' | head -1 | sed 's/.*FAILURES total: *//' | grep -o '^[0-9][0-9]*')
    IMAGEDRIFT_UNKNOWNS=$(echo "$IMAGEDRIFT_SUMMARY" | grep 'could-not-look:' | head -1 | sed 's/.*could-not-look: *//' | grep -o '^[0-9][0-9]*')
    IMAGEDRIFT_COUNT=$(echo "$IMAGEDRIFT_SUMMARY" | grep 'image drift:' | head -1 | sed 's/.*image drift: *//' | grep -o '^[0-9][0-9]*')

    if [ -z "$IMAGEDRIFT_SUMMARY" ]; then
        # DELIBERATELY NOT A CONFIDENT DIAGNOSIS. Two different causes land here and this block
        # cannot tell them apart from the outside: the anchor heading moved, or the check DIED
        # before it printed one. Naming only the first is how the missing-script case above got
        # reported as a renamed heading. So both are named and the output is shown.
        echo "⚠️  UNKNOWN — no '📊 Summary' block in the drift check's output (remote exit $IMAGEDRIFT_RC)."
        echo "  Either the heading this fold-in anchors on has moved, or the check died before it"
        echo "  reached the summary. Nothing here was read, so the state is UNKNOWN, not green."
        echo "  Last few lines of what came back:"
        echo "$IMAGEDRIFT_OUT" | tail -5 | sed 's/^/    /'
        EXIT_CODE=1
    elif [ -z "$IMAGEDRIFT_FAILURES" ] || [ -z "$IMAGEDRIFT_UNKNOWNS" ]; then
        echo "⚠️  UNKNOWN — the summary was found but its FAILURES/could-not-look counters were not"
        echo "  readable. A counter reading UNKNOWN rather than a number means the check could not"
        echo "  look; a missing label means the cross-file contract moved. Either way this is not"
        echo "  green."
        echo "$IMAGEDRIFT_SUMMARY" | sed 's/^/    /'
        EXIT_CODE=1
    elif [ "$IMAGEDRIFT_FAILURES" -gt 0 ] || [ "$IMAGEDRIFT_UNKNOWNS" -gt 0 ]; then
        echo "❌ BROKEN (check-drift.sh exit $IMAGEDRIFT_RC; $IMAGEDRIFT_FAILURES fatal, $IMAGEDRIFT_UNKNOWNS could-not-look)"
        echo "  Note: a fatal finding here is NOT the drift count. It is either a could-not-look, or"
        echo "  the unresolvable count/name-set having moved — i.e. a NEW stale compose project."
        echo "  Failed findings:"
        echo "$IMAGEDRIFT_OUT" | grep '❌\|⚠️' | sed 's/^ */    /'
        echo "  Summary:"
        echo "$IMAGEDRIFT_SUMMARY" | sed 's/^/    /'
        EXIT_CODE=1
    elif [ "$IMAGE_DRIFT_PROMOTED" = "1" ] && [ "${IMAGEDRIFT_COUNT:-0}" -gt 0 ]; then
        # Only reachable once somebody flips IMAGE_DRIFT_PROMOTED. See that constant for why doing
        # so before an apply path exists makes this script ignorable rather than safer.
        echo "❌ $IMAGEDRIFT_COUNT container(s) on an image git no longer pins (IMAGE_DRIFT_PROMOTED=1)"
        echo "$IMAGEDRIFT_SUMMARY" | sed 's/^/    /'
        EXIT_CODE=1
    else
        if [ "${IMAGEDRIFT_COUNT:-0}" -gt 0 ]; then
            echo "✅ Measured — $IMAGEDRIFT_COUNT drifted (REPORTED, not asserted: v1 is alert-only, D-01)"
        else
            echo "✅ Every running container matches its pin in git"
        fi
        echo "$IMAGEDRIFT_SUMMARY" | sed 's/^/  /'
    fi
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
    # Extended again 2026-09-18 (quick task 260918-c12) when the container image-drift block was
    # added. Same discipline as the three amendments above, and for the third time stated because
    # it keeps nearly being forgotten: the tail is updated in the SAME COMMIT as the block that can
    # now reach it. A tail that lists every block except the failing one sends the reader to the
    # green ones and costs them exactly the time this message exists to save.
    # Extended again 2026-09-18 (plan 05-02) when the library underscore-dir guard was added. Same
    # discipline, same commit, fourth statement of it. Note this one can fail on a host the rest of
    # the tail never mentions: atlantis, 172.16.1.158.
    #
    # Extended again 2026-09-22 (plan 06-26, GC-09) — AND THIS TIME AS A REPAIR, NOT AN ADDITION.
    # THE DISCIPLINE THE FOUR PARAGRAPHS ABOVE STATE HAD ALREADY FAILED, THREE PLANS RUNNING:
    #   * 06-16 gave the D-04 scan two new fatal conditions (K and L) and made the D-03 CLI
    #     render's `exit 3` reachable;
    #   * 06-17 added the consumers exit-3 arm;
    #   * 06-23 added a third D-04 fatal condition (P, the vacuous asserted set);
    # and the tail was not touched by any of them. Worse, THE D-03 AND D-04 BLOCKS WERE NEVER IN
    # THE LIST AT ALL — that predates this phase, so the three plans above each widened a block
    # the tail had never mentioned. Between them they hold 30 of the 98 executable `EXIT_CODE=1`
    # sites in this file, second and third largest after the dashboard probe. Four in-band
    # restatements of "update the tail in the SAME COMMIT" did not prevent it, WHICH IS EXACTLY
    # WHY IT KEEPS BEING RESTATED: the rule is remembered when you are editing the tail and
    # forgotten when you are editing a block, and it is only ever needed in the second case.
    # So the list below is no longer maintained by recollection. It was REBUILT FROM A MECHANICAL
    # ENUMERATION of every executable `EXIT_CODE=1` site attributed to its owning block, and that
    # enumeration is recorded in
    # .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-26-qhc-knobs-and-tail.txt.
    # IF YOU ADD A BLOCK, RE-RUN THE ENUMERATION RATHER THAN EYEBALLING THIS LIST. A tail that is
    # right about twelve blocks and silent about the thirteenth is the same defect as one that is
    # right about none: it sends the reader to the green ones and costs them exactly the time this
    # message exists to save.
    # NOT ADDED HERE, deliberately: a new `EXIT-CODE BEHAVIOUR CHANGED` notice. This edit creates
    # no new fatal condition — it only names conditions that already existed. 06-23 added the one
    # new notice this round is entitled to (the thirteenth, for condition P).
    #
    # Extended again 2026-09-26 (plan 07-03, D-25) when the music import sweep was added. NOT from
    # recollection: the mechanical enumeration above was RE-RUN, before and after the edit, with
    # the same anchor method — every other block's site count unchanged, the new block's sites
    # attributed to it alone. Both runs are recorded in
    # .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-03-sweep-drive.txt.
    # Like the consumers audit, the sweep carries a ⚠️ BY DESIGN until the first pilot import.
    echo "❌ Health check FAILED. The failing block is whichever one above carries a ❌ or a ⚠️ —"
    echo "   that is any of: the Traefik or Authelia container probes, the Traefik dashboard"
    echo "   probe, the container counts, the music freeze harness, the consumers audit, the"
    echo "   music import sweep, the"
    echo "   library underscore-dir guard, the Jellyfin transcode retention audit, the"
    echo "   vendored-file drift block, the D-03 vendored-config mount block, the D-04"
    echo "   throwaway -l scan, the extended.conf destructive-switch block, or the"
    echo "   container image-drift block."
    echo "   ⚠️ The image-drift block CANNOT fail on the drift count itself — if it is red, it is"
    echo "      a could-not-look or the unresolvable set moved. Do not go looking for a tag."
    echo "   ⚠️ The consumers audit carries a ⚠️ BY DESIGN for as long as CONF-04 is open: its"
    echo "      exit 3 means the D-22 artist rows were read successfully and are sitting at their"
    echo "      RECORDED BASELINE. That is the state this project has written down, not a new"
    echo "      fault — but it is also NOT a pass, and CONF-04 is NOT closed. It clears when"
    echo "      ROADMAP entry criterion E6 discharges CONF-04's Jellyfin half, and on nothing"
    echo "      else. Do not tune it out: the non-zero exit is what makes a later regression back"
    echo "      to the baseline detectable by tooling instead of only by a human reading yellow."
    echo "   ⚠️ The music import sweep carries a ⚠️ BY DESIGN until the first pilot import: the"
    echo "      library holds 0 items and the sweep refuses to call nothing clean (its exit 3)."
    echo "      Once items exist, a ⚠️ there is a could-not-look and a ❌ is a criterion-7 finding."
    exit 1
fi
