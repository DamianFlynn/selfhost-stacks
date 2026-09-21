---
phase: 06-tagger-configuration-and-dry-run
plan: 06
subsystem: infra
tags: [beets-flask, watchdog, inbox, traefik, authelia, cloudflare, dns, security, music-tagging]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-04's running beets-flask rc6, its three registered inboxes, the emptied 02-review, and the D-29 layer-3 baseline pair this plan re-reads four times"
  - phase: 05-inbox-structure-and-the-junk-gate
    provides: "the _inbox tree whose 02-review this plan's throwaway folder transits and leaves empty"
  - phase: 03-tagger-spike
    provides: "friction 9 — a rejected config kills the watchdog while the server keeps serving a page — which is the entire reason firing must be proven separately from registration"
provides:
  - "D-09 discharged in BOTH halves: registered (06-04) and FIRING (here), on two required instruments plus a third"
  - "the measured fact that a beets-flask preview touches neither library.db nor state.pickle"
  - "the dangling-state finding: deleting a folder leaves its dbfolder and session rows behind, and the watchdog logs FileNotFoundError non-fatally"
  - "D-07's exposure shape asserted from the runtime: no host port, t3_proxy only, exactly one router, chain-authelia@file, port 5001"
  - "D-07's EXTERNAL half CLOSED — beets.deercrest.info resolves publicly to Cloudflare proxy addresses and the 302 came back through Cloudflare, not through a curl --resolve override"
  - "the first positive runtime evidence that the musicbrainz plugin is live under rc6's schema, not merely parsed"
affects: [06-07, 06-09, 06-10, 06-11, 06-13, 06-14, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Prove a service FIRES, never only that it registered — the two are separable and a dead watchdog serves a page that looks alive"
    - "Budget a liveness poll against the debounce value, and state the budget in the transcript"
    - "Before polling an API for a string, confirm the schema actually contains that string — a predicate that cannot match is indistinguishable from a dead service"
    - "Probe a port refusal from the LAN address as well as loopback, and run a connecting positive control first"
    - "Record a 'could not look' as UNKNOWN and substitute openly, never silently"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-06-inbox-liveness.txt
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-06-exposure-proof.txt
  modified: []

key-decisions:
  - "The throwaway was built by COPY from an already-duplicated backlog folder, with a source manifest sha256 identical before, during and after — so no unique content was ever at risk"
  - "A third instrument (the persisted beets-flask sqlite state) was recorded even though the plan required two, because it names the folder by path and proves candidate lookup actually happened"
  - "The Traefik HTTP API could not be read unauthenticated; this is recorded as UNKNOWN and three other runtime instruments answer instead, rather than the assertion being quietly downgraded"
  - "Two of my own instruments were defective and both are left visible in the transcript with the cause named, rather than re-run clean"

patterns-established:
  - "Explain an absence before reporting it — the missing Traefik router metric and the missing access-log line each have a named, checked cause"
  - "Use mtime AND ctime to assert a tree is untouched: mtime catches a content write, ctime catches a metadata-only change"

requirements-completed: [CONF-01, CONF-02]

# Metrics
duration: 25min
completed: 2026-09-20
---

# Phase 6 Plan 06: Inbox liveness and the exposure proof — Summary

**A registered inbox was proven to actually FIRE — one throwaway folder in, a completed MusicBrainz preview out, the folder gone and `02-review` back to zero — and the only route to beets-flask was proven from the runtime to be `beets.deercrest.info` behind Authelia, with D-07's outstanding external half closed on the way.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-09-20T23:35Z (first host measurement)
- **Completed:** 2026-09-20T23:54Z
- **Tasks:** 2 of 2
- **Files created:** 2 artifacts. No repo file was modified; nothing was deployed, restarted or recreated.

## Accomplishments

- **D-09 is discharged in both halves.** Registration was 06-04's. Firing is this plan's, and the two are genuinely separable — Phase 3's friction 9 is that a rejected config kills the watchdog while the server keeps serving a page, so inboxes go inert behind a UI that looks alive. The watchdog picked the folder up, chose the right mode for the right inbox (`Enqueuing … as preview`, matching `02-review`'s `autotag: preview`), reached `PREVIEW_COMPLETED` with no exception, and stopped there.
- **The preview found five real MusicBrainz releases.** This is the first positive *runtime* evidence that D-10's list-form `plugins: [musicbrainz]` was not merely accepted by rc6's schema but actually works — the persisted state holds five candidate `album_info` rows for *American Heart* by Benson Boone with real MBIDs, against three items whose artist, title, album and length were read correctly.
- **A preview touches neither `library.db` nor `state.pickle`.** Measured, not inferred from "preview means read-only": the D-29 pair was read four times across this plan and is byte-identical every time, and identical to 06-04's first-start baseline.
- **D-07's external half is CLOSED.** 06-04 closed with it explicitly open — its 302 used `curl --resolve` against the origin, and a Traefik certificate is not evidence that DNS resolves. `beets.deercrest.info` now resolves to Cloudflare proxy addresses from two independent resolvers, `zzz-nonexistent-test.deercrest.info` resolves from neither, and the 302 came back bearing `server: cloudflare` / `cf-ray: …-DUB` / `remote=172.67.175.143`. The path public DNS → Cloudflare → origin → Traefik → Authelia is exercised end to end.
- **The WR-02 defect is absent in both of its halves, asserted from the runtime.** No published port on four independent reads, refused on 5001 *and* 8337 from both `127.0.0.1` and `172.16.1.159` with a connecting positive control on 443 — and Traefik proven able to actually reach the backend, which is the half a decorative router fails.
- **Exactly one of 97 running containers claims the hostname.** That confirms at runtime that 06-04's deletion of the dormant survivor's labels took effect; a second claimant would be a spoofing surface.

## Task Commits

1. **Task 1: D-09 part 2 — drive one throwaway folder through `02-review`, confirm a preview, remove it** — `a686ecc` (feat)
2. **Task 2: D-07 — prove the exposure shape from the runtime, not the file** — `061cdb9` (feat)

## Files Created

- `.planning/…/artifacts/06-06-inbox-liveness.txt` — the firing transcript: the D-17 amendment, the copy-not-move manifest triple, the debounce budget, three instruments with their routes recorded, the removal, the dangling-state finding, and the four D-29 reads.
- `.planning/…/artifacts/06-06-exposure-proof.txt` — the D-07 assertions from `docker inspect`, `docker port`, `ss`, `nc`, the container-label sweep, DNS from two resolvers, HTTPS from two vantage points, plus an appendix carrying the plan-level verification.

Both artifacts' driving scripts are kept on the host at `/mnt/fast/safety/phase06/` and are deliberately **not** committed — this repository is public and holds no non-Markdown data artefacts outside `artifacts/`.

## Decisions Made

- **The throwaway was built from material that is already duplicated.** `Benson_Boone_-_American_Heart-WEB-2025-BENSONBOONE` (mp3) has a FLAC twin in the same population; both are drawn stratum-S1 folders in `06-SAMPLE.md`. Three files were **copied**, never moved, and the source manifest sha256 `f963ce43…` is identical before the copy, after the copy and after the removal. `rsync -a` was deliberately avoided — on `tank` it fails `mkstemp … Operation not permitted` while printing stats that look like success.
- **A third instrument was recorded although two were required.** The plan asked for the log and the API. The persisted `beets-flask-sqlite.db` was added because it names the folder by path in a `task.toppath` row and carries `choice_flag: None` — positive evidence that nothing was chosen and therefore nothing imported, which neither of the other two gives directly.
- **The Traefik API read was recorded as UNKNOWN, not quietly swapped.** The API is `api@internal`, published only via the `traefik.deercrest.info` router which itself carries `chain-authelia@file`; there is no `--api.insecure` and `:8080` carries Prometheus metrics only. That was *demonstrated* (404 from `/api/version`, and the runtime command line quoted) rather than asserted, then three other runtime instruments were used.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] My stage-A pre-state API probe was a silent no-op**
- **Found during:** Task 1, stage A
- **Issue:** The script called `docker exec beets-flask /venv/bin/python - <<'PY'` **without `-i`**. Without `-i` docker does not attach stdin, so python read EOF immediately, printed nothing and exited 0. Section A3 of the transcript shows its route lines followed by no output — which reads like an empty result but is really "could not look". This is 02.1-06's Debug-liveness bug in a new costume: an instrument that cannot speak returns the same silence as an instrument reporting nothing wrong.
- **Fix:** The pre-state quoted in the artifact is from the interactive route-discovery probe run minutes earlier in the same session, before stage A created anything — `{"items":[],"next":null}` on both `/api_v1/session/` and `/api_v1/dbfolder/`. That is a genuine pre-state. Stages B and C use `docker exec -i` and produce output correctly. The provenance is stated in the artifact rather than the earlier reading being presented as the script's.
- **Files modified:** none in the repo
- **Verification:** `06-06-inbox-liveness.txt` § DEVIATION 1
- **Committed in:** `a686ecc`

**2. [Rule 1 - Bug] The poll loop's instrument-2 predicate asked a question the schema cannot answer, and reported a false negative for 242 s**
- **Found during:** Task 1, stage B
- **Issue:** The loop counted occurrences of the folder **name** inside the `/api_v1/session/` response body. A session record carries only `folder_hash`; it never carries the path. The count was therefore structurally pinned at 0 across all 25 polls, and the loop's own summary line reads `API_HIT=0`. Anyone stopping there would report "the inbox did not fire" — while instrument 1 was already showing 2 matching log lines.
- **Fix:** Resolved the real join in stage C — `session.folder_hash == dbfolder.id`, where the `dbfolder` row carries `full_path`. One dbfolder row matches the marker, one session joins to it, `progress: 20` = `PREVIEW_COMPLETED`, `exc: null`. Corroborated by the third instrument, whose `task.toppath` carries the path literally. **The failing poll output is left in the transcript with `API_HIT=0` visible and the cause named**, because the defect is the useful part.
- **Files modified:** none in the repo
- **Verification:** `06-06-inbox-liveness.txt` § DEVIATION 2 and § INSTRUMENT 2
- **Committed in:** `a686ecc`

---

**Total deviations:** 2 auto-fixed, both Rule 1, both my own instruments rather than the plan's.
**Impact on plan:** No scope change and no fact changed. Both cost time, not truth. The second is the one worth carrying forward: a poll predicate that cannot match is indistinguishable from a dead service, so confirm the schema contains the string before polling for it.

## Issues Encountered

- **Deleting the folder does NOT remove beets-flask's state for it.** Measured 20 s after the removal: the `dbfolder` row (pointing at the now-vanished `full_path`) and the `session` row both remain. The watchdog noticed and logged four pairs of `could not list directory` / `FileNotFoundError`, non-fatally — the container is still running with `RestartCount 0` and its original `StartedAt`. The residue is inert as far as this test can see (`PREVIEW_COMPLETED`, `choice_flag: None`, so nothing is pending on it), and the limit is stated: it was **not** tested whether the rows survive a container restart, and the container was deliberately not restarted. **Carry-forward for Phase 7:** if a folder is renamed, moved or removed between preview and import, expect stale `dbfolder`/`session` rows and expect `FileNotFoundError` in the log. Neither is a fault; both will look like one read cold.
- **Traefik emits no `traefik_router_*` metrics at all on this instance,** because router labels are opt-in (`--metrics.prometheus.addRoutersLabels`, default false, and absent from the runtime command line — grep count 0). And there is no `beets-svc` *service* series either, which is the expected result rather than a fault: the Authelia forwardauth middleware short-circuited the request with a 302 before Traefik forwarded it to the backend. The backend is reachable — a direct request from inside the traefik container returned 200 OK from uvicorn — so "no service metric" is positive corroboration that the middleware ran.
- **No access-log line exists for the probe** because `--accessLog.filters.statusCodes=204-299,400-499,500-599` excludes 302. Predicted in the script before the grep ran, and recorded so the silence is not mistaken for a routing failure.
- **`beets.` and `auth.` take different paths from inside the LAN.** From LXC 100, `auth.deercrest.info` resolves to `172.16.1.159` directly while `beets.deercrest.info` goes out through Cloudflare. That asymmetry is why § 5 was also run from the workstation.
- **No `CNAME` is visible in DNS for `beets.deercrest.info`.** Expected for a Cloudflare *proxied* record — Cloudflare flattens and answers with its own anycast A/AAAA regardless of how the record is stored. Recorded so the claim stays "the name resolves to Cloudflare proxy addresses" and is not upgraded to "a CNAME was observed".

## Known Stubs

None. This plan renders no data and wires no path; it is entirely measurement.

## Threat Flags

None. This plan introduced no new surface. It asserted existing surfaces against the plan's own register — T-06-26 (published host port), T-06-27 (a second or middleware-less router), T-06-28 (a curl test passing while browsers fail), T-06-29 (the liveness folder left behind or built from unique material), T-06-30 (a poll shorter than the debounce) — and each is mitigated as written there. T-06-SC held: nothing was installed and no image was pulled; `docker run --rm <image>` was never used, because on a reaped host that is a PULL.

## Outstanding — one item, and it is not a pass

**⚠ The `<human-check>` is UNANSWERED.** Sign in at `https://beets.deercrest.info/` in a real browser and confirm: (1) Authelia challenges first, (2) the beets-flask UI loads after authenticating, (3) no web terminal is offered anywhere in the UI.

Until that is answered, **"Authelia protects it" rests on a curl request that carries no cookies.** That is a real limit on what the 302 proves, not a formality — this estate's documented failure mode is exactly a curl smoke test passing while every browser fails with a bare `431`. The configuration half of item 3 *is* corroborated mechanically: `gui.terminal.enabled: false` in the deployed file. The browser half is not, and is recorded as outstanding in the artifact, here, and in the phase's open items.

> **ANSWERED 2026-09-22 by the operator.** The paragraph above stands as the dated record of what was
> true when this plan closed; it is amended, not rewritten. Operator's words: *"yes beets.deercrest
> dose offer authellia and works"*.
>
> That discharges **items (1) and (2)** — Authelia challenges, and the UI loads after authenticating,
> observed from a real browser. The `431` failure mode this section warns about did not occur, so the
> curl-based 302 is now corroborated by a client that carries cookies.
>
> **Item (3) was not separately confirmed by eye** and is deliberately not read into "works". It stays
> exactly where this paragraph left it: corroborated mechanically by `gui.terminal.enabled: false` in
> the deployed file and by this plan's own observed `Web-Terminal is disabled, skipping setup` log
> line — configuration and runtime evidence, not a visual check.
>
> Recorded in `06-VERIFICATION.md` § Human Verification Required.

## Next Phase Readiness

**Ready for 06-07 onward.** The runtime is proven live end to end — a folder placed in a registered inbox produces a completed MusicBrainz preview, and the only way to reach the UI is through Authelia.

Specifically inherited:

- **Phase 7 must expect dangling state.** See *Issues Encountered*. Plan for stale `dbfolder`/`session` rows after any folder move, and do not read `FileNotFoundError` in the watchdog log as a regression.
- **`02-review` is empty and `04-hold` still holds 06-04's 535 entries.** The `_inbox` tree at close: `01-auto` 0, `02-review` 0, `03-asis` 0, `04-hold` 535, `99-quarantine` 51, `_done` 0.
- **The library is provably untouched.** `/mnt/tank/media/Music` holds 2,674 entries, and **not one** has an mtime or a ctime on or after 2026-09-20 — both instruments used deliberately, since mtime catches a content write and ctime catches a metadata-only change. `/media` is still `RW=false` on the runtime.
- **06-04's other named follow-up is still open and is not this plan's:** `/mnt/fast/stacks/stacks/selfhosted/arrs/beets/flask.yaml` is UNTRACKED on the host, so a future `git pull --ff-only` there will refuse until that one file is deleted.

## Self-Check: PASSED

Both claimed artifacts exist on disk, and both claimed commits are present in this branch's history:

- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-06-inbox-liveness.txt` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-06-exposure-proof.txt` — FOUND
- `a686ecc` — FOUND
- `061cdb9` — FOUND

Both task `<verify><automated>` commands were run as written and exited 0:
`D-09 part 2 recorded; 02-review empty` and `D-07 exposure proof OK`.

**Git delivery note:** this plan ran as a parallel executor in a worktree. STATE.md, ROADMAP.md and REQUIREMENTS.md were deliberately NOT touched — the orchestrator owns those writes after the wave merges.

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-20*
