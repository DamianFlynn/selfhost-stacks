---
phase: quick-260915-k9p
quick_id: 260915-k9p
plan: 01
subsystem: health-checks
tags: [traefik, authelia, health-check, false-red, probe-correctness]
requires:
  - "scripts/quick-health-check.sh WR-09 fatal-probe shape"
  - "traefik-rtr router + chain-authelia@file (stacks/selfhosted/traefik/traefik.yaml)"
provides:
  - "scripts/quick-health-check.sh exits 0 on a healthy estate"
  - "a dashboard probe that asserts entrypoint + router + TLS + Authelia middleware"
  - "detection of a bypassed Authelia chain on the dashboard route (HTTP 200 = violation)"
affects:
  - "Phase 4 gap-closure plan 04-17 (the exit-0 fence prerequisite)"
tech-stack:
  added: []
  patterns:
    - "curl --resolve pinned to loopback: asserts THIS estate's Traefik, not public DNS"
    - "redder-only env overrides (any non-default value forces EXIT_CODE=1)"
    - "scratch harness holding the probe block verbatim, one line swapped, to drive unreachable branches"
key-files:
  created: []
  modified:
    - scripts/quick-health-check.sh
    - scripts/check-server-health.sh
    - stacks/selfhosted/arrs/beets.md
decisions:
  - "The probe was wrong, not the estate: :8080 was never published, so curl exit 7 was correct"
  - "Pass condition is a PROTECTED answer (302 to Authelia, or 401), never 200 — curl sends no cookies"
  - "HTTP 200 on the dashboard route is a VIOLATION: it means chain-authelia@file is out of the path"
  - "Control B's planned address (127.0.0.2) could not work — Traefik binds 0.0.0.0:443, so all of 127/8 answers; used 172.16.1.158 instead"
metrics:
  duration: ~25 min
  completed: 2026-09-15
---

# Quick Task 260915-k9p: Correct the Traefik Dashboard Probe Summary

The dashboard probe had asserted an unpublished port since the day it was written; repointing it at
the real `traefik.deercrest.info` serving chain takes `quick-health-check.sh` from a permanent
exit 1 to **exit 0 with zero `❌` and zero `⚠️`**, while making a bypassed Authelia chain detectable
for the first time.

## What was wrong

`scripts/quick-health-check.sh` curled `/dashboard/` over plain HTTP on port 8080 of LXC 100's
loopback. Measured on 2026-09-15, **before** any change:

```
$ ssh root@172.16.1.159 "docker port traefik"
80/tcp -> 0.0.0.0:80      80/tcp -> [::]:80
443/tcp -> 0.0.0.0:443    443/tcp -> [::]:443
3023/tcp -> 0.0.0.0:3023  3023/tcp -> [::]:3023
3024/tcp -> 0.0.0.0:3024  3024/tcp -> [::]:3024
```

No 8080. `traefik.yaml:48` declares `--entrypoints.traefik.address=:8080` as a
**container-internal** entrypoint and `:57` binds `--metrics.prometheus.entrypoint=traefik` to it,
but `ports:` (lines 85-101) publishes only the four above. So `curl` exit 7 was the *correct* answer
to a question the configuration never made. Code review WR-09 then made that branch fatal, turning
a cosmetic permanent red into a **permanent exit 1 on a healthy estate** — the single line keeping
the estate's only health-check entry point at 1.

**The fix was the probe. The estate was not touched.** No port published, no middleware weakened,
`:8080` entrypoint and its Prometheus binding intact.

## What the probe asserts now

One GET to `https://traefik.deercrest.info/dashboard/`, with `--resolve` pinning the name to
`127.0.0.1`, proves four things at once: the `websecure` entrypoint is listening, the `traefik-rtr`
Host router matched, the certificate validated, and `chain-authelia@file` is in the path. Strictly
more than a loopback hit on an unpublished port could ever have proven.

Measured healthy answer, live:

```
$ ssh root@172.16.1.159 "timeout 60 curl -s -o /dev/null \
    -w '%{http_code} %{redirect_url} ssl_verify=%{ssl_verify_result}' \
    --resolve traefik.deercrest.info:443:127.0.0.1 https://traefik.deercrest.info/dashboard/"
302 https://auth.deercrest.info/?rd=https%3A%2F%2Ftraefik.deercrest.info%2Fdashboard%2F&rm=GET ssl_verify=0
RC=0
```

It deliberately does **not** assert public reachability (the `--resolve` pin is the point: the probe
cannot pass because Cloudflare serves something else, nor fail because public DNS or hairpin NAT
broke) and does **not** assert any authenticated content (`curl` sends no cookies, so demanding a
200 would have been a new permanent red — the same defect class being fixed).

An unauthenticated **200 is a violation**, with its own `❌` and `EXIT_CODE=1`. The old 8080 probe
could never have detected a bypassed auth chain; it was checking a port that answers nothing.

## Run 1 — the healthy run (the success condition)

```
RUN1 2026-09-15T13:50:24Z
=== Quick Server Health Check ===
Traefik: ✅ Running
  Health:
no healthcheck
Authelia: ✅ Running
Containers running: 96
✅ No unhealthy containers
Traefik dashboard: ✅ Protected (HTTP 302 → Authelia)
Vendored-file drift:
  ✅ vendored files match (3): audio.bash, sabnzbd beets-config.yaml, survivor config.yaml
extended.conf destructive switches:
  ✅ extended.conf switches disarmed (2): requireBeetsMatch=false, ConversionFormat in {FLAC,OPUS}
Music freeze harness: ✅ Intact
Music consumers audit: ✅ Both consumers see the library
Jellyfin transcode retention: ✅ Transcode retention intact
RC=0
```

Asserted mechanically, not by eye: `grep -c '❌'` → **0**, `grep -c '⚠️'` → **0**, `RC=0`,
**96 containers**.

Re-run after the commit, against the committed code — `POST-COMMIT 2026-09-15T13:54:42Z`, **RC 0**,
0 `❌`, 0 `⚠️`, same dashboard line.

*The exit 0 was not reached by softening anything.* The probe is strictly stricter than its
predecessor: it asserts four properties instead of zero, and it added a violation branch (200) that
did not previously exist.

## Runs 2-6 — the driven negative controls

Controls A-C are **live and env-driven**; D-E and the remaining branches run in a scratch harness.
**No repo file was edited to drive any control**, which is why no pre-test sha256 / restore fence
was required or taken — the mechanism is `${VAR:-default}` overrides and a throwaway harness under
the session scratchpad, not a temporary edit that has to be reverted.

| # | Control | Driver | Branch fired | RC |
|---|---|---|---|---|
| A | ssh transport failed | `DASH_HOST=root@192.0.2.1` (live) | **255** UNKNOWN, "Nothing was measured" | **1** |
| B | measured inaccessible | `DASH_RESOLVE_IP=172.16.1.158` (live) | **curl exit 7** `❌`, "This IS a measurement" | **1** |
| C | bound expiry | `DASH_RESOLVE_IP=192.0.2.1 REMOTE_TIMEOUT=5` (live) | **124** UNKNOWN, "Nothing was measured" | **1** |
| D | unauthenticated 200 | harness fixture `200 ` | **SUSPICIOUS** `❌`, bypassed Authelia chain | EXIT_CODE **1** |
| E | non-numeric answer | harness fixture `curl: (6) could not resolve` | **non-numeric** UNKNOWN | EXIT_CODE **1** |

Verbatim, the three "could not look" vs "measured" verdicts side by side — visibly different, all
fatal:

```
# A (255)
⚠️  DASH_HOST override in effect — this run cannot report the dashboard green
Traefik dashboard: ssh: connect to host 192.0.2.1 port 22: Operation timed out
⚠️  UNKNOWN — the ssh to root@192.0.2.1 failed (exit 255), so curl never ran.
  Nothing was measured. This is NOT 'the dashboard route is broken'.

# B (curl's own exit — a real measurement)
⚠️  DASH_RESOLVE_IP override in effect — this run cannot report the dashboard green
Traefik dashboard: ❌ Not reachable (curl exit 7 — it ran and could not complete the request)
  This IS a measurement, unlike the two branches above. Exit 7 means nothing is
  listening on 443 at 172.16.1.158; exit 60 means the certificate failed to validate.

# C (124)
⚠️  DASH_RESOLVE_IP override in effect — this run cannot report the dashboard green
Traefik dashboard: ⚠️  UNKNOWN — the dashboard probe exceeded its 5s bound and was killed.
  Nothing was measured. This is NOT 'the dashboard route is broken'.
```

Control D, the branch that matters most, verbatim:

```
Traefik dashboard: ❌ SUSPICIOUS — the dashboard answered 200 UNAUTHENTICATED. The chain-authelia@file
  middleware is not in the path.
  THIS IS DELIBERATELY A VIOLATION AND NOT SUCCESS. curl sends no cookies, so a 200 here
  cannot be an authenticated answer — it means the Traefik dashboard is being served to
  anyone who asks. Check the traefik-rtr middlewares label in stacks/selfhosted/traefik.
EXIT_CODE=1
```

### The harness is the real code, proven

The harness was built by extracting lines 862-911 of the committed script and replacing **exactly
one line** — the `ssh` capture — with a `printf` of the fixture. The diff is the whole audit:

```
$ diff <(sed -n '862,911p' scripts/quick-health-check.sh) probe-block.sh
2c2
< DASH_OUT=$(ssh -n $SSH_OPTS "$DASH_HOST" "timeout $REMOTE_TIMEOUT curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --resolve traefik.deercrest.info:443:$DASH_RESOLVE_IP https://traefik.deercrest.info/dashboard/")
---
> DASH_OUT=$(printf "%s" "$FIXTURE")
```

Every branch below that line is untouched. The harness lives in the session scratchpad and is not
committed.

### All nine branches driven, not five

Beyond the plan's five, the remaining branch classes were driven through the same harness so no
branch ships unexercised:

| Branch | Fixture | Result |
|---|---|---|
| 4 healthy | `302 https://auth.deercrest.info/?rd=...` | `✅ Protected (HTTP 302 → Authelia)`, EXIT_CODE 0 |
| 5 302 elsewhere | `302 https://evil.example.com/login` | `❌ The router answered 302 but NOT to Authelia`, EXIT_CODE 1 |
| 6 401 | `401 ` | `✅ Protected (HTTP 401 from the Authelia chain)`, EXIT_CODE 0 |
| 8 other numeric | `503 ` | `❌ Unexpected answer from the dashboard route (HTTP 503)`, EXIT_CODE 1 |
| 9 empty | `` (empty) | `⚠️ UNKNOWN — ... returned '', which is not an HTTP status`, EXIT_CODE 1 |

## The estate is provably unchanged

`docker port traefik`, before and after, **byte-identical**:

```
80/tcp -> 0.0.0.0:80      80/tcp -> [::]:80
443/tcp -> 0.0.0.0:443    443/tcp -> [::]:443
3023/tcp -> 0.0.0.0:3023  3023/tcp -> [::]:3023
3024/tcp -> 0.0.0.0:3024  3024/tcp -> [::]:3024
```

No 8080 published, no middleware weakened, `traefik.yaml` not in the commit (`git show --stat`
lists three files, none of them Traefik's definition). Every command run against the estate in this
task was a read-only `docker port`, `docker ps` or HTTP GET.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Control B's planned driver address could not have worked**

- **Found during:** Task 3, control B
- **Issue:** The plan asserted that `DASH_RESOLVE_IP=127.0.0.2` would find "nothing listening on
  that loopback address" and so drive the curl-failure branch. That is false: Traefik publishes
  443 on `0.0.0.0`, so **every** address in 127/8 reaches it. Measured directly —
  `--resolve traefik.deercrest.info:443:127.0.0.2` returns `status=302 RC=0`. Run as planned, the
  control would have produced a *healthy* dashboard verdict (red overall only because the
  redder-only override guard fires), and would have proven nothing about branch 3. A negative
  control that does not exercise its branch is worse than none, because the transcript reads as if
  it did.
- **Fix:** Found an address that genuinely refuses on 443 and is reachable from LXC 100 —
  `172.16.1.158` (atlantis; Proxmox serves 8006, so 443 is closed). Confirmed in isolation first:
  `status=000 RC=7`. Used it as control B's driver, which fired branch 3 as intended.
- **Files modified:** none — this changed only which value the control was driven with.
- **Commit:** n/a (verification-only deviation)

**2. [Rule 2 - Missing coverage] Four branch classes had no driven control**

- **Found during:** Task 3
- **Issue:** The plan specified controls for five branches, leaving branch 4 (the healthy 302),
  5 (302 to a non-Authelia target), 6 (401) and 8 (other numeric) unexercised. Success criterion 5
  asks for at least one control per branch *class*.
- **Fix:** Drove all four through the same harness. All behaved correctly, including branch 5,
  which is the one that catches a middleware swap while entrypoint, router and TLS stay healthy.
- **Files modified:** none.
- **Commit:** n/a (verification-only deviation)

**3. [Rule 3 - Blocking] The plan's zero-`localhost:8080` gate collided with its own
correction requirement**

- **Found during:** Task 1
- **Issue:** Task 1 requires the notices to state that the probe used to hit
  `http://localhost:8080/dashboard/`, while its automated gate requires
  `grep -c 'localhost:8080'` to be **0**. Writing the old target verbatim fails the gate.
- **Fix:** Applied this file's own established convention for a withdrawn claim, which exists for
  exactly this situation and is stated in-band at three other sites: *paraphrase, do not quote* —
  "a false statement left in-band verbatim is one that gets re-copied, and it is also one a
  mechanical grep can no longer prove absent." Both notices now describe the old target as
  "plain HTTP on port 8080 of the loopback" and say explicitly that it is paraphrased so a grep
  keeps returning zero. Gate passes at 0; the reader still learns exactly what the old probe did.
- **Files modified:** `scripts/quick-health-check.sh`
- **Commit:** `9db2e39`

### Pre-existing, out of scope, not fixed

**The plan's greppable pipe-rule gate does not pass, and did not pass before this change either.**
`grep -n 'timeout \$REMOTE_TIMEOUT.*|' scripts/quick-health-check.sh | grep -v 'pipefail\|grep -q'`
returns three lines at both the base commit and HEAD:

| Line (HEAD) | What it is |
|---|---|
| 669 | the Traefik `docker inspect` health read — its `\|` is a `\|\|`, a logical or, not a pipe |
| 962, 963 | the drift block's remote sha256 helper, `... \| sha256sum \| cut ...` inside a function string |

Identical at the base commit (lines 636, 840, 841), so this change introduced none of them. The new
capture has **no pipe at all**. Left alone under the scope boundary — these are other blocks'
business, and 669 is arguably a false positive in the grep rather than a defect. Recorded rather
than silently carried.

## Falsified texts corrected in the same commit

Per the WR-09 precedent that a comment stating the opposite of the code is its own defect class
(WR-05), all three files landed in one commit:

1. **`scripts/quick-health-check.sh`** — the probe's in-band notice rewritten to describe what the
   code does; the WR-09 notice at the top corrected **in place**, dated, keeping its 2026-09-14
   evidence as history while recording that the `❌` it called "real and still unfixed" was the
   probe asserting an unpublished port, and that WR-09's fatal-ness is unchanged by the correction.
2. **`scripts/check-server-health.sh:43`** — ran the same wrong probe. Repointed at the real route,
   **keeping its report-only shape** and its `|| echo` fallback; no assertions, bounds or exit codes
   added, since that script has no such contract.
3. **`stacks/selfhosted/arrs/beets.md`** — the closing record's WR-09 block said the dashboard `❌`
   "still pre-dates this phase and is still unfixed". A second dated block was **appended** (the
   WR-09 one was not rewritten — layered dated corrections are this file's convention) recording
   that it was never an estate fault, and quoting the live 2026-09-15T13:50:24Z figures.

### No eighth notice header was added

`grep -c '^# ⚠️  EXIT-CODE BEHAVIOUR CHANGED'` → **7**; `grep -c 'EXIT-CODE BEHAVIOUR CHANGED'`
→ **8**. The documented 7-headers / phrase-count-8 arithmetic is intact. Exit-code behaviour is
genuinely unchanged by this task — the probe was already fatal after WR-09.

### Historical records not rewritten

The re-grep for survivors returned matches only in `README.md:418` (already names the real URL),
`stacks/selfhosted/openwebui/compose.yaml:387` (openwebui's own container healthcheck, unrelated),
and `.planning/**` SUMMARY / VERIFICATION / REVIEW files. **No `.planning/**` record was touched** —
they are dated observations of the old behaviour.

## Verification

| Check | Result |
|---|---|
| `bash -n scripts/quick-health-check.sh` | PARSE-OK |
| `bash -n scripts/check-server-health.sh` | PARSE-OK |
| `grep -c 'localhost:8080' scripts/quick-health-check.sh` | **0** |
| `grep -c 'localhost:8080' scripts/check-server-health.sh` | **0** |
| `grep -n 'DASH_RC=\$?'` | line 864, directly under the pipe-free capture at 863 |
| `grep -c 'resolve traefik.deercrest.info:443:127.0.0.1' scripts/check-server-health.sh` | 1 |
| `grep -c '260915-k9p' stacks/selfhosted/arrs/beets.md` | 1 |
| Notice headers / phrase count | 7 / 8 — unchanged |
| `bash scripts/quick-health-check.sh` | **RC 0**, 0 `❌`, 0 `⚠️` |
| Controls A-E + branches 4,5,6,8,9 | each fired its intended branch |
| `docker port traefik` | unchanged (80, 443, 3023, 3024) |
| `git status` after commit | clean |
| Label `Traefik dashboard: ` | byte-identical; failure tail needed no change |

## Commits

| Hash | Message | Files |
|---|---|---|
| `9db2e39` | `fix(quick): probe the real Traefik dashboard route, not the unpublished :8080` | `scripts/quick-health-check.sh`, `scripts/check-server-health.sh`, `stacks/selfhosted/arrs/beets.md` |

## Known Stubs

None.

## Threat Flags

None. No new network endpoint, auth path, file access pattern or schema change was introduced. The
change is a read-only GET across an existing trust boundary, and the only literals added are a
hostname already public in this repo, RFC 5737 documentation addresses, and loopback.

`T-k9p-02` (elevation of privilege via a bypassed `chain-authelia@file`) moved from *undetectable*
to *detected and fatal* — the 200 branch, driven in control D.

## Self-Check: PASSED

- `scripts/quick-health-check.sh` — FOUND
- `scripts/check-server-health.sh` — FOUND
- `stacks/selfhosted/arrs/beets.md` — FOUND
- commit `9db2e39` — FOUND in `git log`
