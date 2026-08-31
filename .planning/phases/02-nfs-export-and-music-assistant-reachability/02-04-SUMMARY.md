---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 04
subsystem: testing
tags: [bash, music-assistant, jellyfin, nfs, audit-script, credentials, jq, curl]

requires:
  - phase: 01-safety-harness-and-freeze-the-writers
    provides: "the QUAL-01 ffprobe NDJSON snapshot the three proof albums were selected and pre-verified from, and scripts/check-music-freeze.sh — the pattern this script copies"
  - phase: 02-nfs-export-and-music-assistant-reachability
    provides: "02-01's MA credential reset and provider baseline; 02-03's live NFS export, which section 1 now asserts against"
provides:
  - "scripts/check-music-consumers.sh — a read-only audit of all three consumers (export, Music Assistant, Jellyfin) with the estate's three-branch exit contract"
  - "Three pinned, pre-verified proof albums covering the single-artist, multi-disc and Various Artists shapes, keyed on audio_md5"
  - "Two credentials at /mnt/fast/secrets/ on LXC 100, 0600 root-owned, written via stdin"
  - "A measured correction to the MA API contract that three later plans depend on: responses are unwrapped, and music/albums/count cannot be provider-filtered"
affects: [02-05, 02-06, 02-07, 02-09, phase-07-pilot]

tech-stack:
  added: []
  patterns:
    - "Three-route delegation (EXPORT_ROUTE / MA_ROUTE / JELLYFIN_ROUTE) plus an optional HA_ROUTE fallback, extending check-music-freeze.sh's single ZFS_ROUTE idiom"
    - "Three scoped sub-counters (EXPORT_FAILURES / MA_FAILURES / JELLYFIN_FAILURES) so the summary names which consumer failed"
    - "Per-album `scope` field distinguishing what a consumer can structurally reach from what it has failed to find"

key-files:
  created:
    - scripts/check-music-consumers.sh
  modified: []

key-decisions:
  - "Log in to Music Assistant per run rather than caching the JWT — MA 2.11 has no API-token UI and a cached 90-day token would expire silently inside the estate's only regression detector"
  - "Section 5 counts provider-filtered music/albums/library_items and never music/albums/count — count has no provider parameter and returned 87 with and without one"
  - "The Various Artists shape is a D-08 substitute from the backlog; the 13-folder library contains no VA compilation at all"
  - "Jellyfin's address is resolved fresh via docker inspect every run — 192.168.90.31 was wrong, the bare name resolves to Cloudflare, and 172.16.1.76 is unreachable"
  - "CONS-01/02/03 stay Pending: this plan built the instrument, and the instrument reports 5 open failures"

patterns-established:
  - "Provenance over presence: an album match is only accepted when the returned item's provider_mappings include the pinned local instance, checked both server-side and client-side"
  - "Unpinned means fail, never pass-by-default: MA_LOCAL_PROVIDER_INSTANCE empty makes section 2 fail loudly"
  - "Structural-invisibility is warned, not failed — a permanent red trains the reader to ignore the script (check-music-freeze.sh MODE SCOPE precedent)"

requirements-completed: []

duration: 78min
completed: 2026-08-31
---

# Phase 2 Plan 04: The Consumers Audit Script Summary

**`scripts/check-music-consumers.sh` now asserts the export, Music Assistant and Jellyfin from one
file against three pre-verified proof albums — and the act of building it caught three MA API
contract errors, any one of which would have produced a green check off Spotify's catalogue with
the NFS mount absent.**

## Performance

- **Duration:** ~78 min
- **Started:** 2026-08-31T21:15Z (approx.)
- **Completed:** 2026-08-31T22:33Z
- **Tasks:** 3 of 3
- **Files modified:** 1 in-repo (`scripts/check-music-consumers.sh`, 793 lines), plus 2 credential
  files on LXC 100 that are deliberately outside version control

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | *(none — no in-repo files)* | Credentials provisioned on LXC 100; nothing committable by design |
| 2 | *(none — no in-repo files)* | Album selection recorded here and pinned by Task 3 |
| 3 | `16a9fb2` | `feat(02-04): add check-music-consumers.sh, the phase's instrument` |

---

## Task 1 — Credentials

Both live at `/mnt/fast/secrets/` on LXC 100, mode `0600`, root-owned, **written via stdin** so
neither value entered the process list on a host running 100+ containers. Recorded here **by
variable name only**.

| File | Variables | Auth proof | Rotation |
|---|---|---|---|
| `/mnt/fast/secrets/ma-deercrest.env` | `MA_URL`, `MA_TAILNET_URL`, `MA_VERSION`, `MA_USERNAME`, `MA_PASSWORD` | `auth/login` → JWT, then `config/providers` HTTP **200** | project close, with Jellyfin + Discogs |
| `/mnt/fast/secrets/jellyfin-deercrest.env` | `JELLYFIN_URL`, `JELLYFIN_KEY_NAME`, `JELLYFIN_API_KEY` | `/System/Info` **200**, `/Items?IncludeItemTypes=MusicAlbum` **200** | project close, same batch |

`stat -c '%a %U'` reports `600 root` for both. `/mnt/fast/secrets/` already existed at `0700 root`
from Phase 3's `discogs.env`, so the D-39 "mirrors the Discogs pattern" claim is now literally
true — three files, one convention, one rotation batch.

### D-39 deviation: the token is not stored, because MA 2.11 has none to store

D-39 says "mint a 365-day long-lived token". **Music Assistant 2.11 has no API-token UI** — there
is no such card in the Settings grid. Authentication is username + password exchanged for a JWT
via `auth/login`. The JWT's measured life is **90 days** (`iat` 2026-08-31, `exp` 2026-11-29),
which satisfies the *intent* of "long-lived" but not the literal 365.

**The script logs in fresh on every run rather than caching that JWT.** A cached token expires
silently in 90 days, and this script is meant to run unattended for months once plan 02-09 folds
it into `quick-health-check.sh`. A silently-expiring credential inside the estate's only
regression detector is the exact failure mode this project exists to prevent. The stored secret is
therefore the *credential*, not a token — which is why `ma-deercrest.env` carries `MA_USERNAME` /
`MA_PASSWORD` rather than `MA_TOKEN`. The password reaches `curl` through a `jq`-built body on
`--data-binary @-`, never argv.

### D-40: the Jellyfin key is new and attributable

Minted via `POST /Auth/Keys?App=music-consumers-audit` (HTTP 204) using an existing admin key,
then **only the new key is used**. `ApiKeys` row count went **4 → 5, delta exactly 1**.

One correction to Phase 1's note, worth recording because it changes how the next rotation is
planned: the 4 pre-existing rows are **not** unattributable. They are named `jellystats`, `Wizarr`,
`Seerr` and `QuarterMaster` — each maps to a known consumer. D-40's conclusion still holds (minting
a new purpose-named key is right), but the stated *reason* ("nobody can attribute them") was wrong,
and someone rotating these later should know they are identifiable.

---

## Task 2 — The three proof albums

All three selected from Phase 1's QUAL-01 snapshot
(`/mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz`, 9,736 records, 1,244 of them
under `/mnt/tank/media/Music`) and **pre-verified before use as a gate** (D-07).

| # | Shape | Path | `album` | `albumartist` | Tracks | Representative `audio_md5` |
|---|---|---|---|---|---|---|
| 1 | single-artist | `/mnt/tank/media/Music/Chris Norman/Lifelines (2026)` | `Lifelines` | `Chris Norman` | 15 | `39da9daf74c3a4e2dcc0f35a7612d122` |
| 2 | multi-disc | `/mnt/tank/media/Music/Garth Brooks/The Ultimate Hits (2007)` | `The Ultimate Hits` | `Garth Brooks` | 36 | `48556eceed2f2cc16709269ee93aa18f` |
| 3 | various-artists **(D-08 substitute)** | `/mnt/tank/downloads/complete/nzb/unsorted/VA-Mastermix.Essential.Hits.Pop.4.2005-2009-2025` | `Mastermix Essential Hits - Pop 4 - 2005-2009` | `Various Artists` | 50 | `097b998f01a67d2f738d3cf415c9d7f2` |

### Pre-verification evidence

| Check | #1 | #2 | #3 |
|---|---|---|---|
| `albumartist` non-empty | ✅ | ✅ | ✅ |
| distinct `albumartist` across tracks | 1 | 1 | 1 |
| distinct `album` across tracks | 1 | 1 | 1 |
| top-level folder name **byte-identical** to `albumartist` | ✅ `4368726973204e6f726d616e` | ✅ `47617274682042726f6f6b73` | n/a — backlog, staging layout specified below |
| `test -d` from LXC 100 | ✅ | ✅ | ✅ |
| distinct disc numbers | 1 | **2** | 1 |
| present in MA's existing (Spotify-supplied) library | no | no | no |

Folder/`albumartist` agreement matters specifically because plan 02-06 sets
`missing_album_artist_action: folder_name` — agreement now is what makes a later *dis*agreement
diagnostic rather than ambiguous.

### Why #2 is the right multi-disc case

`Garth Brooks/The Ultimate Hits (2007)` is a **flat** folder — 36 audio files, **zero
subdirectories** — carrying 2 discs but only **19 distinct track numbers**. Track numbers collide
across the two discs and nothing but the `disc` tag disambiguates them. That is exactly the shape
Phase 1 flagged (a flat 2CD set where all track numbers collide), and it exercises MA's
`albumartist + os.sep + album` identity key against the case most likely to break it.

`Ed Sheeran/5 (2014)` was the runner-up (5 discs, 32 tracks, also clean). It was rejected because
its album string is the single character `5`, which makes the `search` argument pathologically
noisy — a flaky assertion is worse than a slightly easier one.

`Def Leppard/Rock of Ages - The Definitive Collection (2005)` was **rejected on evidence**: 2 discs
but **two different album strings** — `Rock Of Ages: The Definitive Collection (1)` and `(2)` —
which fails D-07's "album consistent across the album's tracks". A proof album that is itself
mis-tagged makes any later MA failure uninterpretable, which is the whole point of D-07.

### D-08 fired: the library has no Various Artists compilation

Measured, not assumed. The library's 13 top-level folders are: Def Leppard, Taylor Swift, P!nk,
Ed Sheeran, Garth Brooks, Katy Perry, Lady Gaga, Sabrina Carpenter, Hawthorne Heights, Vengaboys,
BLACKPINK, Chris Norman, Benson Boone. **Every one is a single named artist.** There is no
`Various Artists` folder and no album in the library carrying that `albumartist`.

The shape is therefore substituted from the backlog per D-08 rather than silently skipped.
`VA-Mastermix.Essential.Hits.Pop.4.2005-2009-2025` was chosen because all 50 files carry
`albumartist = Various Artists` and one identical `album` string across **40 distinct track
artists** — a genuine compilation, not a mislabelled single-artist release.

**Required staging for plan 02-07:** the substitute is served from the D-04/D-15 **temporary
export** over a scratch directory under `tank/downloads`, and must be staged as
`Various Artists/Mastermix Essential Hits - Pop 4 - 2005-2009/` so the folder name agrees with the
tag the same way the two library albums do. It must **never** be staged under
`/mnt/tank/media/Music` — CLAUDE.md forbids staging unmanaged content there and Phase 1 sealed the
tree.

Rejected VA candidates and why:
- `VA-Mastermix.Issue.446-202` — mixed `albumartist`: 10 files say `Various Artists`, 10 say
  `Mastermix`. Fails D-07's consistency check.
- `Various.Artists-70s.Essential.Hits-...-⭐️-xpost` — clean tags, but an emoji in the folder name
  is a needless variable to introduce into an NFS path under test.
- Anything from the `NOW That's What I Call Music` sets — see the Spotify note below.

### The Spotify layer-2 defence is not theatre

MA's library **already contains** `NOW That's What I Call Music! 116` and `NOW That's What I Call
Music! 98`, both credited to **Various Artists, from Spotify** (`spotify--g2SQC45P`). Had the
obvious VA proof album been a `NOW` release from the backlog, it would have collided head-on with a
Spotify entry and an unfiltered query would have reported a pass with the mount absent. A Mastermix
DJ-service compilation is not on Spotify, so the collision is structurally impossible.

### Nothing was written

`find /mnt/tank/media/Music -newermt "2026-08-31 21:00" | wc -l` → **0**, checked at the start and
again at the end of the plan. This task read the snapshot and `stat`'d directories; it repaired no
tag, moved no file and wrote nothing to the library. Nobody holds `rw` on Music until Phase 6.

---

## Task 3 — `scripts/check-music-consumers.sh`

793 lines, mode `100755` with the exec bit staged in git, committed as `16a9fb2`.

### The `# Where it runs:` answer

**Host-resident on LXC 100** (`root@172.16.1.159`, from `/mnt/fast/stacks`), matching
`check-music-freeze.sh`. Unlike that script this one has *no* "the query cannot be one ssh'd
command" forcing constraint — every check here is a single remote call. It is host-resident because
of **credentials and reachability**, and the header states the split rather than leaving it
implicit:

- Jellyfin publishes no host port and refuses `localhost:8096`; it is reachable **only** from
  LXC 100. Close to decisive on its own.
- D-39 and D-40 both put credentials at `/mnt/fast/secrets/` on LXC 100.
- atlantis is reachable from LXC 100 for `exportfs -v`, as `check-music-freeze.sh:129` already
  reaches it for `zfs`.
- The one pull in the other direction — the NUC SSH key — is resolved by `HA_ROUTE`.

`HA_ROUTE` follows the `ZFS_ROUTE` precedent: if `HA_SSH_KEY` is set and readable the
`ha mounts info` assertion runs; otherwise `HA_ROUTE=skipped`, a `warn()` fires, and section 5
falls back to the MA-side equivalents **which always run**. On LXC 100 today it reports `skipped`,
as expected. The header carries an explicit "do not fix this by adding the key" note with the
reasoning: the MA-side assertions are *stronger* evidence than mount state — an emergency bind
leaves `/media/music` empty, so the provider-scoped album count and all three exact-match
assertions fail anyway.

### Exit-code contract — verified on LXC 100

| Invocation | Exit | Verified |
|---|---|---|
| `--baseline` | **0** (after printing the summary) | ✅ |
| default, with failures present | **1** | ✅ |
| `--bogus-flag` | **2** | ✅ |
| `-h` (reprints the header block) | **0** | ✅ |

`exit $(( FAILURES > 0 ? 1 : 0 ))` is deliberately absent — it cannot express `--baseline`.
`grep -vE '^\s*#' | grep -c 'FAILURES > 0 ? 1 : 0'` → `0`.

### Baseline run — 2026-08-31T22:30Z, MA 2.11.0b0

```
  MA version (live):           2.11.0b0   (assertions proven at 2.11.0b0)
  export route:                ssh:172.16.1.158
  ma route:                    http://172.16.1.31:8095
  jellyfin route:              docker-inspect:192.168.90.25:8096
  ha route:                    skipped   (skipped is expected on LXC 100 — see header)
  pinned provider instance:    <UNPINNED — set by plan 02-06>
  proof albums pinned:         3   (target 3: single-artist, multi-disc, various-artists)
  albums matched in MA:        0   (target 3, exact name+albumartist, provider-attributed)
  albums matched in Jellyfin:  2   (target 2, exact name+albumartist)
  jellyfin out-of-scope:       1   (scope!=library — reported, not asserted)
  MA albums, local provider:   unknown   (target >= 3)
  toolchain missing:           0
  export assertions failed:    0
  MA assertions failed:        5
  Jellyfin assertions failed:  0
  FAILURES total:              5
```

Read that as designed behaviour, not breakage:

- **Section 1 (CONS-01) is fully green — 10/10.** The export applied by 02-03 is asserted end to
  end: client exactly `172.16.1.31`, neither `*` nor a CIDR, all of `ro` / `all_squash` /
  `anonuid=568` / `anongid=568` / `mountpoint` present, `no_root_squash` absent (D-51 gate 2),
  `nfs-server` active on atlantis and **not** active on LXC 100.
- **Section 4 (Jellyfin) is green for both in-scope albums** — exact `Name` + `AlbumArtist`
  matches, scoped to the Music library's ItemId.
- **The 5 MA failures are all one root cause:** `MA_LOCAL_PROVIDER_INSTANCE` is unpinned because
  plan 02-06 has not created the local filesystem provider yet. That is the *correct* state — the
  script refuses to pass by default, which is exactly what section 2 exists to do.

### Section 6's heading is load-bearing

`📊 6. Summary`, literal, with a comment in the file saying so. Plan 02-09's fold-in will anchor on
it with `sed -n '/^📊 6\. Summary/,$p'`, the way `quick-health-check.sh:83` anchors on
`check-music-freeze.sh`'s section 7. `grep -c '^📊 6\. Summary'` over a `--baseline` run → `1`.

---

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — Bug] `music/albums/count` cannot be provider-filtered; the plan's section 5 gate was unimplementable and would have false-passed**

- **Found during:** Task 3 (API probing before writing section 5)
- **Issue:** The plan specifies *"MA-side: `music/albums/count` for the pinned instance id is at
  least 3."* That command **has no provider parameter**. Verified two independent ways: MA's own
  `/api-docs/commands.json` lists its parameters as `favorite_only` and `album_types` and nothing
  else; and empirically it returned **87 both with and without** a `provider` argument, while the
  provider-filtered album list held 9 items. Implemented literally, this liveness gate would have
  reported **GREEN off Spotify's catalogue with the NFS mount broken or entirely absent** — a
  seventh unearned pass in a project that has recorded six.
- **Fix:** Section 5 counts **provider-filtered `music/albums/library_items`** instead, with the
  measurement recorded as API SHAPE NOTE 3 in the header so nobody "simplifies" it back.
- **Commit:** `16a9fb2`

**2. [Rule 1 — Bug] MA `POST /api` responses are not wrapped in `.result`**

- **Found during:** Task 3
- **Issue:** RESEARCH.md's worked `api()` helper filters with `.result[]`. Against 2.11.0b0,
  `auth/login` returns `{access_token, success, user}` and `config/providers` returns a **bare
  array**. A `.result[]` filter errors — and inside the `|| true` idiom this codebase uses, an
  error reads as "no providers", i.e. a silent pass.
- **Fix:** All jq filters read the unwrapped shape, and every response is type-checked
  (`jq -e 'type == "array"'`) before use, so a future shape change fails loudly instead of
  emptily. Recorded as API SHAPE NOTE 1.
- **Commit:** `16a9fb2`

**3. [Rule 1 — Bug] `${2:-\{\}}` in the research skeleton's `api()` produces literal `\{\}`**

- **Found during:** Task 3 (first probe run failed with `jq: Invalid numeric literal`)
- **Issue:** The default-argument idiom in the skeleton emits backslashes into the JSON body, so
  any call made without an explicit `args` object sends malformed JSON.
- **Fix:** Both `ma_api()` and `provider_filter()` build their bodies with `jq -nc --argjson` and
  default `args` to `{}` in a plain conditional. No hand-assembled JSON anywhere in the file.
- **Commit:** `16a9fb2`

**4. [Rule 2 — Missing critical functionality] `exportfs -v` line wrapping would let a client string be credited to the wrong export**

- **Found during:** Task 3
- **Issue:** `exportfs -v` puts the `client(options)` field on its **own continuation line** when
  the path is long, which it is here. A naive `grep -q '172.16.1.31'` over the whole output passes
  if *any* export mentions the NUC, not necessarily the Music one.
- **Fix:** Section 1 joins continuation lines onto their path with `awk` before parsing, then
  extracts the client field and option list for that specific path. The client is compared with
  `==` for exact equality — a substring match would accept `172.16.1.310`.
- **Commit:** `16a9fb2`

**5. [Rule 2 — Missing critical functionality] Client-side provenance re-check on every album match**

- **Found during:** Task 3
- **Issue:** Trusting only the server-side `provider` argument makes the Spotify defence
  single-layered.
- **Fix:** Every accepted match is additionally checked client-side — the returned item's
  `provider_mappings[].provider_instance` must contain the pinned instance id, or the assertion
  fails with the actual mappings printed. Cheap, and it closes the gap if a future MA release
  loosens what `provider` means.
- **Commit:** `16a9fb2`

**6. [Rule 3 — Blocking] Nested `ssh` consumes the outer script's stdin**

- **Found during:** Task 1/2 probing (a remote script silently truncated mid-run)
- **Fix:** `SSH_OPTS` centralises `-n -o BatchMode=yes -o ConnectTimeout=5` and every `ssh`
  invocation in the file uses it.
- **Commit:** `16a9fb2`

### Deliberate departures from the plan text

**A. `192.168.90.31` is documented as WRONG rather than used as the Jellyfin address.**
The plan's `key_links` pattern requires the literal `192.168.90.31` to appear in the file, and it
does — inside a header block that names it as the **first of three wrong ways** to reach Jellyfin,
alongside the bare name `jellyfin` (resolves to Cloudflare's public edge from LXC 100 because of
`search deercrest.info`) and `172.16.1.76` (unreachable under macvlan host isolation). The address
in use is resolved fresh on every run with
`docker inspect jellyfin --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}'`,
which returned `192.168.90.25` today. Pinning a literal that docker IPAM can move is precisely how
a check ends up asserting against nothing.

**B. The `provider_filter` name is a shell function; the JSON argument is `provider`.**
The plan's acceptance criterion greps for `provider_filter`. That string is the name of the
function that injects the filter, so the intent is greppable and hard to drop by accident; the
actual MA argument, per `/api-docs/commands.json`, is `provider` and takes a provider **instance
ID** (string or list). Verified: a real instance id narrows the list, and an instance id that does
not exist returns `[]` — which is what makes the unpinned state fail loudly rather than pass.

**C. The Various Artists album is `warn`ed, not `fail`ed, in the Jellyfin section.**
Jellyfin bind-mounts `/mnt/tank/media` only and has no mount reaching `/mnt/tank/downloads`, so the
D-08 substitute is **structurally** invisible to it. Failing there would be a permanent red for
something that is not a defect, and `check-music-freeze.sh`'s MODE SCOPE block records what a
permanent red does to a reader. Each pinned album therefore carries a `scope` field
(`library` / `temp-export`), the Jellyfin target adjusts to `3 - out-of-scope`, and the count is
reported in the summary so the exclusion stays visible rather than silent.

**D. D-39's "365-day token" is satisfied as a per-run login.** See Task 1 above for the reasoning.

**E. Tasks 1 and 2 produced no commit.** Both are declared `files: none in-repo` by the plan —
Task 1's outputs are two files at `/mnt/fast/secrets/` that must never be committed, and Task 2's
output is the album selection, which is pinned by Task 3 and recorded here. `git status --porcelain`
showed nothing to stage for either.

### Not fixed — logged, out of scope

- `/mnt/fast/stacks` on LXC 100 carries two pre-existing untracked files
  (`stacks/selfhosted/monitoring/prometheus.yaml.bak`,
  `stacks/selfhosted/wrappers/monitoring.app.yaml.disabled`). Unrelated to this plan; left alone.
- Phase 1's characterisation of Jellyfin's 4 `ApiKeys` rows as unattributable is inaccurate (see
  Task 1). Corrected here; the decision it supported is unchanged, so no plan needs revising.

## Authentication gates

None. Both credentials were provisioned inside the plan and authenticate. The MA password had been
set by the operator before this plan started, which is what unblocked 02-01's recorded gap.

---

## Requirements

**`requirements-completed` is deliberately empty.** The plan's frontmatter claims CONS-01/02/03,
but this plan built the *instrument*, not the outcomes:

| Req | State after this plan | Owner |
|---|---|---|
| CONS-01 | Export assertions are now **green, 10/10**, but the requirement's own 1d/1e sub-criteria need a mounted client | 02-05 |
| CONS-02 | The instrument reports **5 open failures** — the local provider does not exist yet | 02-06 |
| CONS-03 | Cannot be evaluated; there is no mount | 02-05 / 02-07 |

Marking any of them complete here would be the seventh unearned pass. `REQUIREMENTS.md` is
therefore unchanged by this plan.

## Repo hygiene — leak check

Run before the final commit. The repository is public and has one prior credential exposure still
recoverable via `git log -S`.

| Check | Result |
|---|---|
| literal MA password value in tracked files | **0 hits** |
| literal MA password value anywhere in the working tree (excl. `.git`) | **0 hits** |
| credential *assignments* (`MA_PASSWORD=` / `MA_TOKEN=` / `JELLYFIN_API_KEY=` / `DISCOGS_USER_TOKEN=` at line start) in tracked files | **0 hits** |
| `git grep -nE '(eyJ[A-Za-z0-9_-]{10,}\|Bearer [A-Za-z0-9._-]{20,})' -- . ':!*.lock'` | **0 hits** |
| the minted Jellyfin API key's literal value, tracked **and** untracked | **0 hits** |
| `git ls-files .planning/ \| grep -vc '\.md$\|config\.json'` | **0** — no non-markdown artifact added |
| `pilot-albums.txt` referenced anywhere in the script or present in the phase directory | **no** |

The script contains the strings `MA_PASSWORD` and `JELLYFIN_API_KEY` only as **variable
references** (`"$MA_PASSWORD"`, `${JELLYFIN_API_KEY}`), which is the repo's stated convention
(`NETWORK.md:19`).

## Wave gate

`bash scripts/check-music-freeze.sh` on LXC 100 → **exit 0, FAILURES total: 0**, 102-container
estate, ownership mismatches 0, fence assertions 0. The Phase 1 harness is intact after this plan.

## Notes for the next plan

1. **02-05 / 02-06 must set `MA_LOCAL_PROVIDER_INSTANCE`** near the top of
   `scripts/check-music-consumers.sh`. Until it is set, sections 2, 3 and 5 fail by design. The
   provider must also be `type: music` (D-28) — the script asserts that too.
2. **02-07 must stage the VA substitute as `Various Artists/Mastermix Essential Hits - Pop 4 -
   2005-2009/`** under the temporary export's scratch directory in `tank/downloads`, so the folder
   name agrees with the tag exactly as the two library albums do.
3. **The script is not yet on LXC 100.** The tested copy was removed after verification so a later
   `git pull` into `/mnt/fast/stacks` lands the committed version cleanly rather than colliding with
   an untracked file. Pull before running it there.
4. **02-09's fold-in anchor is `📊 6. Summary`** — literal, and commented as such in the file.
5. **MA drift detection is live.** The run banner prints `live` next to `proven-at`. When
   `auto_update` moves MA past `2.11.0b0`, the script warns (does not fail); re-prove the provider
   assertions and update `MA_VERSION_PROVEN`.

## Threat Flags

None. This plan added a read-only audit script and two credential files outside version control.
No new network endpoint, auth path, file-access pattern or schema at a trust boundary was
introduced. The `music-consumers-audit` Jellyfin key is admin-scoped by Jellyfin's own design —
that scope is a property of Jellyfin's API-key model, not a new surface, and it is registered
against T-02-15 with an attributable name so it can be rotated.

## Self-Check: PASSED

- `scripts/check-music-consumers.sh` — FOUND (793 lines, mode 755)
- commit `16a9fb2` — FOUND in `git log`
- `/mnt/fast/secrets/ma-deercrest.env` on LXC 100 — FOUND, `600 root`
- `/mnt/fast/secrets/jellyfin-deercrest.env` on LXC 100 — FOUND, `600 root`
- all three proof album directories — `test -d` succeeded from LXC 100
- exit codes 0 / 1 / 2 / 0 — all four verified on LXC 100
