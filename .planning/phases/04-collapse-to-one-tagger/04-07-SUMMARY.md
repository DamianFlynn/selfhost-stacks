---
phase: 04-collapse-to-one-tagger
plan: 07
subsystem: infra
tags: [teardown, deletion, dns, github-issue, fence, absence-proof, d-04, d-26, d-28, d-33, d-35]

# Dependency graph
requires:
  - plan: 04-01
    provides: "the fence copies (wrtag.db line 882, the two Phase 1 survivor DBs, the config.yaml.old audit copy) and the 35-path sha256 baseline every pre-delete re-assertion is made against"
  - plan: 04-03
    provides: "PRE_DELETION_SHA 5d0af70 and the 04-03 deletion commit e63e0fd, which the #306 closing comment cites as the recovery path"
  - plan: 04-06
    provides: "the candidate census, whose pre-deletion red run is this plan's driven negative control"
provides:
  - "the wrtag and soulbeet appdata trees are GONE from LXC 100, each after its copy was re-proven"
  - "the survivor's two stale databases are GONE, clearing the path for D-28's single fresh library.db"
  - "sentriz/wrtag:v0.20.0 removed by name; absence proven by an explicit `No such image`"
  - "spike03-image-headroom.sh KEEP_PATTERNS no longer exempts the retired image from reaping (Pitfall 11)"
  - "wrtag.deercrest.info deleted from Cloudflare; dig NXDOMAIN on two resolvers, control name still resolving"
  - "issue #306 CLOSED with the four D-26 facts and an explicit answer to its own salvage proposal (Pitfall 14)"
  - "a reusable absence-proof script driven BOTH ways (CLEAN on a live daemon, UNKNOWN/exit 3 on a dead one)"
affects: [04-09, 04-11, 04-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Absence proofs are driven in both directions in the same run: the identical script is executed once normally (CLEAN) and once with DOCKER_HOST pointed at a non-existent socket (UNKNOWN, exit 3), so the green is known not to be a dead instrument"
    - "Every count-zero answer is paired with a control that must return non-zero through the same code path: the ancestor filter against a running image, the Cloudflare list against a name that must still exist, `alpine:latest` against the registry"
    - "A DNS absence claim is preceded by a wildcard test (a random name must return NXDOMAIN), because under a wildcard `dig` can never prove a record is gone"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-07-SUMMARY.md
  modified:
    - scripts/spike03-image-headroom.sh
  deleted:
    - "(host) /mnt/fast/appdata/media/wrtag"
    - "(host) /mnt/fast/appdata/arrs/soulbeet"
    - "(host) /mnt/fast/appdata/arrs/beets/config/musiclibrary.blb"
    - "(host) /mnt/fast/appdata/arrs/beets/config/library.db"
    - "(host) /mnt/fast/appdata/arrs/beets/config/config.yaml.old"
    - "(host image) sentriz/wrtag:v0.20.0"
    - "(Cloudflare) CNAME wrtag.deercrest.info"

key-decisions:
  - "The wrtag KEEP_PATTERNS entry was REMOVED rather than left in place, and the reason is recorded in the file: an allow-list entry is unconditional, so one naming a retired image exempts a dead image from reaping forever"
  - "The #306 closing comment answers the issue's salvage proposal explicitly rather than closing silently, and names the git SHA the config is recoverable from, so the salvage is refused-with-a-reason rather than lost"
  - "Four pre-existing unreferenced .env variable names were RECORDED, not removed: only SOULBEET_SECRET_KEY is attributable to this phase, and the file is gitignored, untracked and out of this plan's scope"

requirements-completed: [TAGR-03]  # the ESTATE half: 04-03 completed the repo half (definitions + Renovate); this plan removed the host appdata, the resident image, the reap exemption and the public DNS record, so TAGR-03 is now true of the estate and not only of the repo.
requirements-partial: [TAGR-04]    # the soulbeet half is now COMPLETE (issue #306 closed with evidence). The `audio.bash` beets-block strip is the other half and belongs to 04-10/04-11.

# Metrics
duration: ~25min
completed: 2026-09-11
---

# Phase 4 Plan 07: Retire the Non-sabnzbd Runtime State Summary

**Everything of wrtag and soulbeet is now gone from the estate — appdata, image, reap exemption, public DNS record and the issue — and every one of those absences was proven by an instrument that was separately seen to answer. Each of the five deletions was preceded by its own fence re-assertion, and all five live files hashed byte-identical to their 04-01 baseline, so nothing had drifted since it was fenced. Both routine health checks are still exactly at the 04-01 baseline.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-09-11 ~23:12Z
- **Completed:** 2026-09-11 ~23:37Z
- **Tasks:** 3 of 3
- **Files:** 1 repo script modified (1 commit); 5 host paths, 1 image and 1 DNS record deleted

## Accomplishments

- **D-04 is now a measured fact about the estate.** Before this plan, "one tagger" was true of git
  and false of the host: two retired appdata trees, a resident 172 MB retired image, a public
  hostname and a reap exemption all still existed.
- **Nothing was deleted on trust.** All five live files re-hashed **identical to their 04-01
  values**, so none had been opened since fencing and the contingency branch (take a fresh
  `.backup` first) never had to fire. Each fence copy was re-matched to its MANIFEST line **by
  path**, not by sha — 04-01 warned that lines 847/848 share a sha256, so a sha-keyed match is
  ambiguous.
- **The false-green class REVIEWS row 2 names is closed here by driving it.** The absence proof was
  run twice from the same file: `CLEAN` against the live daemon, and `UNKNOWN … exit 3` against
  `DOCKER_HOST=unix:///nonexistent-04.sock`. A green from this instrument is now known to require a
  daemon that answered.
- **The candidate census matched the CORRECTED expectation exactly** (REVIEWS row 9): 24 beets
  databases, not 1. The classifier was not narrowed, `.blb`/`.bak` were not excluded and sabnzbd was
  not special-cased.
- **The routine path never moved.** Freeze RC 0 with zero `❌` and the two permanent mode `⚠️`;
  quick-health-check RC 0 with the Traefik dashboard as its only `❌`. Measured after the deletions
  and again after the host pull.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | Fence-gated deletion of the wrtag/soulbeet trees and the survivor's old databases | **none** — host-only, no repo file changed (the 04-01 precedent). Evidence below |
| 2 | Containers, image and reap-protection | **`02e5aa0`** |
| 3 | Remove the wrtag DNS record and close #306 | **none** — Cloudflare API and GitHub only |

**Plan metadata:** this SUMMARY's own commit.

## Delivery

| Item | Value |
|---|---|
| Pushed | `2f19e29..02e5aa0  main -> main` |
| origin `refs/heads/main` | `02e5aa0e58ebd15fa861a78d7c5b920b471ffce4` |
| Host `/mnt/fast/stacks` HEAD before | `2f19e29` (= origin at plan start; precondition met) |
| Host HEAD after `git pull --ff-only` | **`02e5aa0`** (Fast-forward) |
| Host untracked files | the same 2 pre-existing (`prometheus.yaml.bak`, `monitoring.app.yaml.disabled`) before and after — not mine, untouched |

---

## Task 1: fence-gated deletion

### Precondition gate (all met before anything was deleted)

| Precondition | Value |
|---|---|
| 04-01 confirmation table has no BLOCKER for these paths | 4/4 rows `y`/`y` (lines 846, 847, 882, 888) |
| 04-06 candidate first run recorded `retired path PRESENT` for them | yes — all 5 named in 04-06 control (a), so the guard existed and fired **before** deletion |
| host HEAD = origin HEAD | `2f19e29` = `2f19e29` |
| host porcelain | 2 lines, both pre-existing and not mine — **recorded, not required empty** (04-06 deviation 2) |

### Container-reference check — producer status captured FIRST

```
docker ps -aq        rc=0   id_count=97      (empty would be UNKNOWN on a ~100-container estate, not "none")
docker inspect       rc=0   rows=97
positive control     '/sabnzbd ' rows: 1
rows matching media/wrtag|arrs/soulbeet|arrs/beets/config:  NONE
```

Any UNKNOWN here would have halted the task before the first `rm`. None occurred.

### Per-target re-assertion, immediately before each delete

| # | Target | Live sha256 | = 04-01? | Fence copy | Fence sha = MANIFEST? | `integrity_check` | Entries |
|---|---|---|---|---|---|---|---|
| 1 | `media/wrtag` | `10414308…26de` | **y** | `library-db/media_wrtag_data_wrtag.db` (line 882) | **y** (`56861d39…40be`) | **ok** | 3 |
| 2 | `arrs/soulbeet` | `83028925…8576` | **y** | git `5d0af70`, workstation-verified byte-equal | **y** | n/a (yaml) | 3 |
| 3 | `arrs/beets/config/musiclibrary.blb` | `98f9f13b…ec10` | **y** | `library-db/arrs_beets_config_musiclibrary.blb` (line 847) | **y** (`b75527ea…ea40`) | **ok** | 1 |
| 4 | `arrs/beets/config/library.db` | `54440dd1…14c6` | **y** | `library-db/arrs_beets_config_library.db` (line 846) | **y** (`d59d1a87…0efb`) | **ok** | 1 |
| 5 | `arrs/beets/config/config.yaml.old` | `0559906f…b184` | **y** | `audit/arrs-beets-config.yaml.old.20260911T180026Z` (line 888) | **y**, and fence sha **equals the live sha** | n/a (yaml) | 1 |

- **Every live sha equalled its 04-01 value**, so the "something opened it — take a fresh `.backup`
  first" branch was never needed. It was present and would have halted the delete.
- soulbeet's `data/` was re-measured empty at delete time: `find data -mindepth 1 | wc -l` = **0**.

### The deletion guard (S5 / CR-01)

For each target, in order: refuse any `..` component → `realpath -e` → the resolved path must
**equal one of five allow-list entries typed literally in the script** → the resolved path must
equal the given path → print `find | wc -l` and the full listing → `rm` → `test ! -e`.

No glob appeared in any `rm` argument, no variable could be empty (guarded), and **no `prune` of any
kind was run**. `rm -rf` was used only for the two directories; the three files used `rm -f`.

```
GONE  /mnt/fast/appdata/media/wrtag                              (3 entries, 54k)
GONE  /mnt/fast/appdata/arrs/soulbeet                            (3 entries, 6k)
GONE  /mnt/fast/appdata/arrs/beets/config/musiclibrary.blb       (36,864 B)
GONE  /mnt/fast/appdata/arrs/beets/config/library.db             (53,248 B)
GONE  /mnt/fast/appdata/arrs/beets/config/config.yaml.old        (1,419 B)
```

### The survivors are untouched

| Item | Before | After |
|---|---|---|
| `Music/` visible (positive control) | yes | **yes** |
| `Music/` `du -sk` | 1455677k | **1455677k** |
| `config.yaml` sha256 | `8b09078d…37ae` | **identical** |
| `state.pickle` sha256 | `f6a9a1ad…4bc7` | **identical** |

`/mnt/fast/appdata/media/` kept its 8 other children and `arrs/` its 11 — only the two named
subtrees left.

### Post-delete CANDIDATE census — RC **1**, 4 s

The complete expected-red set, and nothing outside it:

```
✅ tagger definitions: found exactly stacks/selfhosted/arrs/beets/beets.yaml
❌ beets databases: expected=1 … found 24   (12 × sabnzbd .config/beets/*, 12 × sabnzbd scripts/library.blb*)
❌ retired path PRESENT: /mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb
❌ retired path PRESENT: /mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets.log
❌ retired path PRESENT: /mnt/fast/appdata/arrs/sabnzbd/config/.config/beets
   rw on Music, D-21 consumer exception: jellyfin [running]
✅ no container in any state holds rw reaching Music, apart from the D-21 exception
   Tagger-capable inventory: lidarr [running] ro · sabnzbd [running] none
```

| Counter | Before (04-06) | **After** | Target |
|---|---|---|---|
| tagger definitions | 1 | **1** | 1 |
| beets databases | 26 | **24** | 1 (= SURVIVOR_DB, absent until 04-09) |
| tagger databases | 1 | **0** | 0 |
| retired paths present | 7 | **3** | 0 (04-11) |
| rw on Music, non-tagger | 0 | **0** | 0 |
| rw on Music, tagger-capable | 0 | **0** | 0 |
| rw on Music, Jellyfin D-21 | 1 | **1** | documented exception |
| tagger-capable containers | 2 | **2** | reported |
| FAILURES total | 9 | **4** | — |

**`beets databases` is 24 and that is correct** (REVIEWS row 9, 04-06 § Next Phase Readiness): every
one of the 24 is a sabnzbd beets database and they are genuine beets DBs until 04-11 deletes them.
`SURVIVOR_DB` is reported absent, which is expected until 04-09 creates the fresh one. The
classifier was **not** narrowed, `*.blb`/`.bak` were **not** excluded, and sabnzbd was **not**
special-cased — doing any of those to match a prose expectation would recreate DEF-03-01's
blindness.

### ROUTINE runs — within the 04-01 baseline

| Check | Where | 04-01 baseline | Post-delete | Post-pull (final) |
|---|---|---|---|---|
| `check-music-freeze.sh` (no env) | LXC 100 | RC **0**, no `❌`, 2 permanent mode `⚠️`, FAILURES 0 | RC **0**, identical set, FAILURES 0 | RC **0**, identical set, FAILURES 0 |
| `quick-health-check.sh` (no env) | workstation | RC **0**, sole `❌` Traefik dashboard, no `⚠️` | RC **0**, identical | RC **0**, identical |

The routine run leaked **zero** census rows (`retired path PRESENT` count = 0) and printed the
candidate notice, so 6b is still dormant. The fold-in's positive controls both answered: `Music
freeze harness: ✅ Intact`, `Jellyfin transcode retention: ✅ Transcode retention intact`.

**The finding set is identical to the baseline, not merely a subset.** No new red at this wave
boundary.

---

## Task 2: containers, image and reap-protection

### Estate enumeration (RC captured; empty or non-zero = UNKNOWN)

| Query | RC | Result |
|---|---|---|
| `docker ps -a --format '{{.Names}} {{.Image}}'` (no status filter) | 0 | 97 containers; **0** matching `wrtag\|soulbeet`; **0** named `beets`; `sabnzbd` present (positive control) |
| `docker network ls` | 0 | 22 networks; **0** matching `wrtag\|soulbeet\|music` |
| `docker volume ls` | 0 | 42 volumes; **0** matching `wrtag\|soulbeet\|music` |
| `docker ps -a -q --filter ancestor=sentriz/wrtag:v0.20.0` | 0 | **empty** |
| *control:* same filter on `ghcr.io/linuxserver/sabnzbd:5.1.0` | 0 | **1** — proves the filter discriminates rather than always returning empty |

### Image removal — by name, never prune

```
docker image rm sentriz/wrtag:v0.20.0     rc=0
  Untagged: sentriz/wrtag:v0.20.0
  Untagged: sentriz/wrtag@sha256:3f33c13c…97e
  Deleted:  sha256:c435c4870104…  + 4 further layer deletions
```

| Item | Value |
|---|---|
| Declared image size (upper bound — shared layers) | **171,800,290 B** (~172 MB) |
| `df -h /` before | `126G 86G 34G 72%` |
| `df -h /` after | `126G 86G 34G 72%` (see Deviation 1 — below `-h` resolution) |
| Remaining images matching `wrtag\|beets\|sabnzbd` | `metasauce/beets-flask:v2.0.0-rc6`, `lscr.io/linuxserver/beets:2.13.1-ls349`, `ghcr.io/linuxserver/sabnzbd:5.1.0` — **no wrtag** |

### The absence proof, driven BOTH ways from the same file

**(1) Live daemon — must print `CLEAN`:**

```
  containers enumerated: 97  (positive control sabnzbd: present)
  no container named wrtag|soulbeet
  image absence proven by explicit not-found: [Error response from daemon: No such image: sentriz/wrtag:v0.20.0]
CLEAN                                                            RC=0
```

**(2) `DOCKER_HOST=unix:///nonexistent-04.sock` — must print `UNKNOWN` and exit 3:**

```
failed to connect to the docker API at unix:///nonexistent-04.sock … no such file or directory
UNKNOWN docker ps rc=1                                           RC=3
```

The error branch fires **before** any absence is claimed, so a dead daemon can never produce
`CLEAN`. RC 0 would have been `PRESENT-IMAGE`; RC 124 is its own `UNKNOWN` (timeout); only the
literal `No such image` counts as absence.

### KEEP_PATTERNS edit

| Check | Result |
|---|---|
| `bash -n` | pass |
| `grep -v '^\s*#' … \| grep -c 'sentriz/wrtag'` | **0** (also 0 with the POSIX `[[:space:]]` form) |
| `metasauce/beets-flask` / `lscr.io/linuxserver/beets` / `linuxserver/beets` / `redis` still present | 1 / 1 / 1 / 1 |
| Diff | 10 insertions, 2 deletions — the entry, plus a comment recording **why** it was removed rather than left |

### Unreferenced `.env` variable NAMES (no values read or printed)

`stacks/selfhosted/arrs/.env` is gitignored and was **left unchanged** (optional hygiene; nothing
breaks). Names with zero references in any tracked `stacks/` file:

| Name | Attributable to this phase? |
|---|---|
| `SOULBEET_SECRET_KEY` | **yes** — its only consumer was `soulbeet.yaml`, deleted in `e63e0fd` |
| `GENIUS_API_KEY` | no — pre-existing |
| `SLSKD_API_KEY` | no — pre-existing |
| `SLSKD_URL` | no — pre-existing |
| `TRAEFIK_AUTH_BYPASS_KEY` | no — pre-existing |

Control: `LIDARR_API_KEY` resolves to `stacks/selfhosted/arrs/lidarr.yaml`, so the search was not
vacuously returning zero.

---

## Task 3: DNS record and issue #306

### Cloudflare (D-33)

**Token handling (S7 / DEF-03-21):** the token was read with the bash builtin `read -r TOK < <path>`
inside a script delivered to the host, and reached curl only through
`-H @<(printf 'Authorization: Bearer %s\n' "$TOK")`. It never entered argv, was never echoed, was
never written to disk, and no `ps`/`pgrep -a`/`top -c` was run during the window. The script
contained the token file **path**, never a value; `set -x` was deliberately not used; `TOK` was
unset at the end. Nothing token-shaped appears in this SUMMARY.

| Step | `success` | Count | Detail |
|---|---|---|---|
| Zone lookup `?name=deercrest.info` | **true** | 1 | zone id truncated in all output |
| List `?name=wrtag.deercrest.info` | **true** | **1** | `type=CNAME name=wrtag.deercrest.info proxied=true` — name asserted byte-equal before deleting |
| `DELETE /dns_records/<id>` | **true** | — | — |
| Re-list `?name=wrtag.deercrest.info` | **true** | **0** | a failed list would have been UNKNOWN, never 0 |
| *Control:* list `?name=beets.deercrest.info` | **true** | **1** | proves the count-0 above is discriminating |

Guards that did not need to fire but were present: >1 matching record → stop; 0 → report "already
absent"; any `success != true` → UNKNOWN, no delete.

### `dig` confirmation

**Wildcard test first** — without it, `dig` cannot prove absence on this zone:

| Name | Before | After |
|---|---|---|
| `zz-no-such-name-04-07.deercrest.info` | NXDOMAIN, empty | — (proves **no wildcard** exists) |
| `wrtag.deercrest.info` | NOERROR, `104.21.83.117 172.67.175.143` | **NXDOMAIN, empty** |
| `beets.deercrest.info` (control) | NOERROR, resolves | **still resolves** |

Cleared on the **first** attempt (no retry window needed) and cross-checked on a second resolver:
`wrtag @8.8.8.8` empty, `beets @8.8.8.8` resolving.

### Issue #306 (D-26, Pitfall 14)

The four facts, each verified before the comment was written:

1. **Image gone from GHCR.** `docker manifest inspect ghcr.io/terry90/soulbeet:latest` → exit 1,
   `manifest unknown`; `:v0.6.0` (the tag the issue itself names) → exit 1, `manifest unknown`;
   **positive control** `alpine:latest` → exit 0. The control is what makes this an explicit
   not-found rather than a network or auth error read as absence.
2. **Never deployed.** Unfiltered `docker ps -a`: 97 containers, rc 0, `sabnzbd` control present,
   0 matching.
3. **Data directory empty.** 0 entries under `data/` at deletion time.
4. **Definition and config deleted** in `e63e0fd91078870dbaf28253e25cff4fce19583a`, recoverable at
   `5d0af708ae9f04b9ab491cec731b6551ba6bb205`; the appdata tree deleted in Task 1 after its config
   was proven byte-identical to that git copy.

The comment answers the issue's **own salvage proposal** (fold soulbeet's config into the manual
beets config before deleting): deliberately not done here, because Phase 6 (CONF-01…05) owns the
survivor's configuration and Phase 3 set the direction, with the file recoverable at the named SHA
so Phase 6 starts from the same text. It also records that `beets.md` still describes "two beets,
one library" and that correcting it belongs to this phase's closing record — claimed as outstanding
rather than as done.

| Check | Result |
|---|---|
| `gh issue view 306 --json state` | **CLOSED**, comments = 1 |
| Last comment contains `ghcr.io/terry90/soulbeet` / `e63e0fd9107887…` / `Phase 6` / `5d0af708ae9f…` | **all present** |
| Negative control: comment contains a secret path | **absent** |
| `#305` | **OPEN** (untouched) |
| `#307` | **OPEN** (untouched) |
| Plan `<verify>`: `dig` empty + control resolving + state CLOSED | **DONE**, rc 0 |

---

## Deviations from Plan

### 1. [Measurement note] `df -h /` cannot see the 172 MB the image freed

- **Found during:** Task 2.
- **Issue:** the plan asks to "record freed size and `df -h /`". `df -h /` reads
  `126G 86G 34G 72%` both before and after — 172 MB is below `-h` resolution on a 126 G filesystem,
  so the reading is unchanged on a correct outcome.
- **Resolution:** recorded as measured rather than dressed up. The authoritative evidence that space
  was reclaimed is the five `Deleted: sha256:…` layer lines and the subsequent `No such image`, not
  the `df` delta. (`spike03-image-headroom.sh` makes the same point in its own header: treat the
  per-image figure as an upper bound and trust the measured `df` delta — which here is below the
  instrument's granularity.)

### 2. [Defective count, recorded not satisfied] `❌` grep returns 5 where `FAILURES total` is 4

- **Found during:** Task 1, candidate census.
- **Issue:** a naive `grep -c '❌'` over the candidate transcript returns **5** while the script's own
  counter reports **4**. The fifth match is the trailing banner line `❌ 4 failed checks`, which is
  the summary *of* the failures, not another failure.
- **Resolution:** the four findings are itemised above and the script's counter is the authority. No
  transcript was edited and no finding was suppressed to make a grep agree.

### 3. [Rule 2 — additions] Four controls added beyond the plan's text

Each closes a way the plan's own check could have passed while blind:

- **Ancestor-filter positive control.** The plan requires the wrtag ancestor filter to be empty. An
  always-empty filter would satisfy that. The same filter was run against
  `ghcr.io/linuxserver/sabnzbd:5.1.0` and returned 1.
- **Registry positive control.** `alpine:latest` (exit 0) alongside the two soulbeet probes, so
  `manifest unknown` is known to be a registry answer.
- **Cloudflare list control.** After the delete returned count 0, the same call against
  `beets.deercrest.info` returned 1.
- **DNS wildcard test.** A random name returns NXDOMAIN, proving no wildcard — without which
  `dig` could never have proven the record gone, and the plan's `dig`-empty acceptance would have
  been unsatisfiable for a reason unrelated to the deletion.

### 4. [Scope boundary] Four unreferenced `.env` names are pre-existing and were not acted on

Only `SOULBEET_SECRET_KEY` is attributable to this phase. `GENIUS_API_KEY`, `SLSKD_API_KEY`,
`SLSKD_URL` and `TRAEFIK_AUTH_BYPASS_KEY` predate it. The plan says record the names and leave the
file unchanged; the file is also gitignored and untracked. Names only — no value was read or
printed.

### Not a deviation, recorded because it was the risk

**The plan's expected-red set was correct and was not adjusted.** 04-07's Task 1 text already
carried the REVIEWS row 9 correction (24-ish beets DBs, `SURVIVOR_DB` absent, the three sabnzbd
retired paths), and the live census matched it exactly. Nothing in the classifier, the census or the
plan prose was edited to make the two agree.

## Deferred Issues (out of scope, recorded only)

1. **Four pre-existing unreferenced `.env` variable names** (Deviation 4). Cosmetic; removing them
   changes nothing at runtime.
2. **`stacks/selfhosted/arrs/beets.md` still documents soulbeet** (11 mentions) and still describes
   "two beets, one library". Owned by the phase's closing/D-25 record, and named as outstanding in
   the #306 comment rather than silently left.
3. **The two pre-existing untracked host files** (`prometheus.yaml.bak`,
   `monitoring.app.yaml.disabled`) are still untracked and untouched. Any later assertion demanding
   an empty host porcelain is defective until they are dealt with separately (04-06 deviation 2).

## Threat Flags

None. No new network endpoint, auth path or trust boundary was created — this plan only removed
them. The register's seven entries were each mitigated and measured:

- **T-04-07-01 (tampering via `rm`)** — five-path literal allow-list, `realpath -e` equality, `..`
  refusal, count + full listing before each delete, `test ! -e` after, with `Music/` as a positive
  control proving we could still look.
- **T-04-07-02 (data with no copy)** — every delete preceded by its fence re-assertion; all five live
  shas equalled 04-01, so nothing had drifted; the fresh-`.backup` branch existed and was not needed.
- **T-04-07-03 (Cloudflare token disclosure)** — `read -r` builtin + `-H @<(printf …)`; no argv, no
  echo, no `ps`/`pgrep -a`, no disk write, `unset` at the end, nothing token-shaped in this file.
- **T-04-07-04 (DNS zone tampering)** — exact-name lookup, `success: true` required on every read,
  exactly one record required, returned name asserted byte-equal before the DELETE.
- **T-04-07-05 (public comment disclosure)** — facts only; negative control confirms no secret path
  in the comment.
- **T-04-07-06 (DoS via image removal)** — removed by name after the ancestor filter was empty *and*
  shown to discriminate; **no `prune` of any kind was run**.
- **T-04-07-07 (false-green absence proofs)** — producer status captured first everywhere; `sabnzbd`
  positive control; `No such image` required; the error branch driven with an unreachable
  `DOCKER_HOST` and seen to exit 3.

## Known Stubs

None.

## Issues Encountered

- No release names, credentials or `.env` values were printed at any point.
- Host scratch (`/mnt/fast/scratch-04/07`) was removed behind the same S5 guard and asserted gone,
  along with its now-empty parent, with `/mnt/fast/stacks` still visible as the positive control.

## Next Phase Readiness

- **04-09** inherits a survivor `config/` holding **no database at all** — `library.db`,
  `musiclibrary.blb` and `config.yaml.old` are gone, while `config.yaml`, `state.pickle`, `Music/`,
  `beets.sh`, `beet.log`, `.bash_history` and `.cache/` remain. Creating the single fresh
  `library.db` (D-28) is now unobstructed. `state.pickle` sha `f6a9a1ad…` is the pre-`up` baseline
  it should re-record **after** `up`.
- **04-11** still has 3 retired paths and 24 beets databases to clear, and it owns the census
  promotion. Expect `tagger-capable containers: 2` (lidarr + sabnzbd), not 1.
- **04-13** can quote the counters above as the post-retirement half of the D-25 evidence, and
  should correct `beets.md`'s soulbeet text (Deferred 2).
- **Any later plan** doing a DNS absence proof on this zone: there is **no wildcard**, confirmed by
  NXDOMAIN on a random name, so `dig` is a valid instrument here.

## Self-Check: PASSED

- FOUND commit `02e5aa0`; it is on `origin/main` (`02e5aa0e58ebd15…`) and on the host at `02e5aa0`.
- FOUND `scripts/spike03-image-headroom.sh`; `bash -n` clean; non-comment `sentriz/wrtag` count 0;
  the other four KEEP_PATTERNS entries intact.
- All five host paths absent (`GONE-OK`, rc 0) with the `Music/` positive control visible; `Music/`
  `du` and `config.yaml`/`state.pickle` sha256 unchanged.
- Image absent by explicit `No such image`; the identical check exits 3 with `UNKNOWN` on a dead
  daemon.
- `dig wrtag.deercrest.info` empty/NXDOMAIN on two resolvers with the control still resolving;
  Cloudflare list count 0 with its own control at 1.
- `#306` CLOSED with all four required tokens in its comment; `#305` OPEN; `#307` OPEN.
- Routine freeze RC 0 and quick-health-check RC 0, both with exactly the 04-01 baseline finding set.
- `git diff --stat 83d44ef HEAD -- .planning/STATE.md .planning/ROADMAP.md` is **empty**; no
  `gsd-sdk state.*` or `roadmap.*` verb was called. No commit deleted any tracked file.
- sabnzbd's databases were **not** touched; no `prune` was run; host scratch removed and asserted gone.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-11*
