---
phase: 06-tagger-configuration-and-dry-run
plan: 13
subsystem: music-consumers
tags: [conf-04, music-assistant, d-22, d-36, artist-entities, jellyfin]
requires: ["06-03"]
provides:
  - "CONF-04's Music Assistant half, measured against the live 2.11.0b2"
  - "research assumptions A1 and A2, both resolved against the running server"
  - "MA_VERSION_PROVEN moved to 2.11.0b2 in the same commit as its re-proof"
affects:
  - "scripts/check-music-consumers.sh"
  - "stacks/selfhosted/arrs/beets.md"
tech-stack:
  added: []
  patterns:
    - "resolve an API assumption against the server's own schema, never against a call that merely succeeded"
    - "prove a predicate can FAIL before believing its green (planted-positive control)"
    - "could-not-look kept distinct from nothing-is-wrong via the literal house strings"
key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-13-ma-artist-entities.txt"
  modified:
    - "scripts/check-music-consumers.sh"
    - "stacks/selfhosted/arrs/beets.md"
decisions:
  - "A2 CONFIRMED against GET /api-docs/commands.json; a successful library_items call was explicitly not accepted as the resolution"
  - "A1 CONFIRMED behaviourally on 2.11.0b2 rather than by source read — the SSH route to the add-on does not exist on this estate, and behaviour is the stronger evidence anyway"
  - "CONF-04 recorded as two separate verdicts, never summed: Jellyfin OPEN, MA proven with one characterised discrepancy"
  - "Row 1's cap-at-3 vs Twista-specifically left explicitly undecidable on a sample of one, and carried to Phase 7 rather than guessed"
metrics:
  duration: "~1h of measurement across two sessions (interrupted twice by spend limits)"
  completed: "2026-09-21"
  tasks: 3
  commits: 4
---

# Phase 6 Plan 13: Music Assistant Artist-Entity Read-Back Summary

Closed CONF-04's Music Assistant half against the live 2.11.0b2 under the D-36 operator gate, resolving both standing research assumptions against the server's own schema first — and left CONF-04 itself OPEN on its Jellyfin half rather than summing the two into a verdict.

## What was done

**Task 1 — the D-36 gate.** Re-probed before asking, because the standing measurement was three days old: ICMP 3/3 with 0% loss, TCP `8095` and `8123` both open, and — because a `nc -z` success only proves a listener accepted a handshake — both services confirmed at the HTTP layer (MA `/info` serving `2.11.0b2`, HA returning 200). The maintenance window recorded on 2026-09-20 had closed. Presented that with both caveats attached (the `MA_VERSION_PROVEN` drift, and that A1 and A2 were both unresolved); the operator answered **`run-now`** — *"Run the check (option 1)"*.

**Task 2 — A2, A1, then the read-back.** All three in that order, because relying on an unresolved assumption is what the task existed to stop.

**Task 3 — the verdict**, written into `beets.md` with both consumers on one row as two verdicts.

## Findings

**A2 — CONFIRMED.** `GET /api-docs/commands.json` (311 commands, 190 KB) declares `music/tracks/library_items`, `return_type: Array of Track` — a bare array, so not `.result`-wrapped — and the `Track` schema declares an `artists` property, with `provider` a documented parameter. A call that merely succeeded was deliberately not accepted as the resolution: a command can answer and still not be the one carrying the field, which is precisely how A2 arose.

**A2's side effect is worth more than A2.** `music/albums/count` declares **only** `favorite_only` and `album_types` — it has **no `provider` parameter at all**. So "it silently ignores its provider argument" was understated: the argument does not exist, and the integer returned counts the whole library including Spotify. That is now a schema fact in the script rather than an anecdote.

**A1 — CONFIRMED behaviourally on 2.11.0b2.** The source-read route is closed (no `HA_SSH_HOST` in the secrets file), but behaviour is stronger evidence than a source file anyway. Rows 2 and 3 each carry a **single-name `Artist` tag** and a two-name `ARTISTS` tag, and MA returns both names as distinct entities — the second name exists in no other tag on the file, so `ARTISTS` was read and split on `;`. `MA_VERSION_PROVEN` moved `2.11.0b0` → `2.11.0b2` in that same commit.

**The D-22 read-back — identity, not arity.** Every artist returned is a distinct library entity with its own `item_id` and browseable `library://artist/N` uri, and no name anywhere contains a `;`:

| Row | Target | MA | Entities | mb ids |
|---|---|---|---|---|
| California Gurls | 2 | **2** | `Katy Perry \| Snoop Dogg` (73, 244) | 2 |
| Just Give Me a Reason | 2 | **2** | `P!nk \| Nate Ruess` (63, 201) | 2 |
| Jewels n' Drugs | 4 | **3** | `T.I. \| Lady GaGa \| Too $hort` (159, 209, 217) | 4 |

**The `mb_id_count == 1` caveat was measured, not waved:** 4, 2, 2. Not one row carries a single id, so the short-circuit cannot fire on any of them and all three genuinely exercise the splitter.

**A trap the plan did not anticipate, found in the schema and cleared.** `library_items` takes a `summary` parameter defaulting to **true** — "slim summary items containing only the fields needed for a list view". Had the slim shape truncated `artists[]`, every count above would have been measuring a list-view stub while looking healthy. Read at both settings: identical in length, names, item_ids and uris. The default is left in place deliberately and the reason recorded in the script.

**Row 1 characterised rather than dropped.** Two candidate causes are ruled out by measurement — the `;` delimiter (rows 2 and 3 prove the splitter works on this build) and the `mb_id_count` short-circuit (four ids; it would have returned 1, not 3). The loss is located at MA's **artist-entity stage**: `Twista` exists nowhere among MA's 66 library artists under any `/wista/i` spelling, and `Lady GaGa` is a pre-existing entity named from the `ARTIST` tag, which explains the spelling but not the missing fourth. **Left open honestly:** the distribution is 1,220 tracks at 1 artist, 22 at 2, 2 at 3, none above 3, and this file is the library's only 4-value tag — so "MA caps at 3" and "Twista specifically failed to map" cannot be told apart from a sample of one. Phase 7's first ≥4-artist track discriminates. Manufacturing a test case would mean writing to the library, which D-25 forbids here for exactly the phantom reason.

## Deviations from Plan

**None affecting scope.** Two notes:

1. **[Rule 3 — blocking] The A1 source-read route does not exist.** The plan assumed A1 could be re-confirmed against the running build; `ma-deercrest.env` declares no `HA_SSH_HOST`/`HA_SSH_KEY`, so the add-on's installed `tags.py` is unreachable. Resolved by testing A1 behaviourally instead, which satisfies the acceptance criterion ("a verdict against the running 2.11.0b2, not against the 2.10.4 source read") more directly than a source read would have. Recorded in the artifact as a could-not-look on the *route*, not on A1.
2. **DEF-06-12-01 (path rule 2) was deliberately not adopted**, per the operator's deferral to Phase 7 and 06-14's ownership. Scope not widened.

## Method notes

The house rule that "could not look" stays distinct from "nothing is wrong" was applied to my own checks, not just the estate's:

- **Task 1's verify greps this artifact for an option id as its proof an answer was recorded** — so listing the three ids in the question text would have satisfied it off the question alone. They were kept out, the omission documented in the artifact, and the predicate exercised both ways: it failed on exactly that one line beforehand (the other three greps passing) and passed against a planted positive on a scratch copy.
- **The manifest comparison was given a planted-difference control**, because "identical" is worthless if `cmp` cannot see a change.

Both were cheap, and this phase has lost seven plans to predicates that could never match or never fail.

## Safety

**Nothing was written.** `LC_ALL=C find` manifests over the three proof albums (88 entries; path, size, mtime) are identical before and after. D-21's fenced `rw` grant never fired, the `:ro` invariant is unbroken, and **MA holds no phantom** — which matters precisely because MA never purges stale entries (D-25), and is why Jellyfin was proven first and MA last.

**Credentials (T-06-66).** `/mnt/fast/secrets/ma-deercrest.env` measured `600 root` and was gated on refuse-not-source; sourced without `set -a`; password reached `jq` via `$ENV.MA_PASSWORD`, never argv; JWT reached curl only through `-H @<(printf …)`. Neither was printed. `/proc/<pid>/cmdline` is world-readable on LXC 100.

**D-17 holds.** The provider instance `filesystem_local--XJaJWNUS` is named explicitly on every read, returns all 1,244 tracks, and the path is not narrowed — DJ content stays visible. `music/albums/count` was not used as evidence for anything.

## Carried to Phase 7

- **CONF-04 is a named entry blocker**, OPEN on its Jellyfin half (probe-time option; 0 of 1,244 rows moved). The two halves are recorded separately and **must not be summed**.
- **Every `%aunique{}` firing is an MA risk**: `missing_album_artist_action: folder_name` falls back to `Various Artists` silently when folder and tag disagree, while `config/providers/get` still reads back `folder_name` — and an `%aunique{}` firing makes them disagree by construction.
- **The D-34 option is live-service state git does not capture.** Its only protection is the by-name assertion in `check-music-consumers.sh` § 4.
- **A second ≥4-artist track** settles cap-at-3 vs Twista-specifically.

## Commits

| Commit | Task | What |
|---|---|---|
| `bc38065` | 1 | the three-part gate measurement, MA back online at 2.11.0b2 |
| `af521f6` | 1 | the operator's answer recorded verbatim with its option id |
| `8182525` | 2 | A1/A2 resolved, D-22 read-back, `MA_VERSION_PROVEN` moved |
| `2874c4b` | 3 | CONF-04's verdict in `beets.md`, two consumers, two verdicts |

## Self-Check: PASSED

All three claimed files exist on disk (`check-music-consumers.sh` 101,958 b; `beets.md` 128,993 b; the artifact 24,730 b) and all four commit hashes are present in `git log`. `bash -n scripts/check-music-consumers.sh` passes and the script still carries `ma_fail` and `UNKNOWN, not green` **in code with comments stripped**. All three task verifies exit 0. No earlier phase section was edited — the earliest changed line in `beets.md` is 1786, inside the Phase 6 section that starts at 1667. STATE.md and ROADMAP.md were not touched.
