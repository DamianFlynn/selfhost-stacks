---
phase: 6
slug: tagger-configuration-and-dry-run
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-09-20
approved: 2026-09-20
---

> **Status note (2026-09-20, after plan verification).** `nyquist_compliant: true` — every task in
> all 14 plans carries an `<automated>` verify command, no watch-mode flags, and no unbounded remote
> pipelines (confirmed by `gsd-plan-checker`). `wave_0_complete` stays **false** on purpose: the
> ❌ W0 rows below are *built by this phase's own plans* and do not exist yet. Each one's owning plan
> is named in the map, so ❌ means "scheduled, not yet built" — **not** "unowned".

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `06-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + python3 assertion scripts. **This repository has no unit-test framework by design** — no `tests/`, no `pytest.ini`, no `package.json`, no `setup.cfg` (measured 2026-09-20). Do **not** introduce pytest for this phase. |
| **Config file** | none — by design |
| **Quick run command** | `scripts/check-music-freeze.sh` |
| **Full suite command** | `scripts/quick-health-check.sh` (folds in `check-music-freeze.sh`, `check-music-consumers.sh`, `check-jellyfin-transcode.sh`) |
| **Estimated runtime** | full suite bounded by `REMOTE_TIMEOUT` (default 120 s) per remote command |

**Standing rules that bind every check in this phase** (README § Health Checks):
1. **Fail closed**, and keep *"could not look"* distinct from *"nothing is wrong"*.
2. **Bound remote commands Linux-side** — macOS has no GNU `timeout`; `timeout N cmd | wc -l` exits 0 silently, so the remote string needs `set -o pipefail` and the ssh RC must be read.
3. **Assert, don't report.**

---

## Sampling Rate

- **After every task commit:** the task's own assertion block
- **After every plan wave:** `scripts/check-music-freeze.sh`
- **Before `/gsd-verify-work`:** `scripts/quick-health-check.sh` exits 0
- **Max feedback latency:** ~120 s (one `REMOTE_TIMEOUT` window)

---

## Per-Task Verification Map

Task IDs are assigned by the planner; this map is keyed by requirement until plans exist.

| Req | Behaviour to prove | Decision | Test Type | Automated Command | Exists | Status |
|-----|--------------------|----------|-----------|-------------------|--------|--------|
| CONF-01 | `copy: yes` / `move: no` in the **server-committed** config, not the confuse view | D-30 | assertion | `docker exec -u beetle beets-flask /venv/bin/python -c "…get_config(commit_to_beets=True); print(beets.config.dump(full=True))"` + grep | ❌ W0 | ⬜ pending |
| CONF-02 | `incremental: yes` **and** `incremental_skip_later: yes` read back | D-30 | assertion | as above | ❌ W0 | ⬜ pending |
| CONF-02 | the trap **fires** and is **defeated** — negative control, not a read-back | D-31 | driven negative control | `scripts/phase06-incremental-control.sh`, two `-c` overlays; assert `taghistory` contents then the re-offer | ❌ W0 | ⬜ pending |
| CONF-03 | every oracle top-level == an `ALBUMARTIST`, **case-exact**; `Various Artists/` present; `Compilations/` absent | D-15, D-27 | oracle diff + class assertion | `beet move -p` output vs committed expected tree | ❌ W0 | ⬜ pending |
| CONF-04 | N distinct artist **entities** in Jellyfin (not one artist named `A; B`) | D-22, D-34 | API read-back | `GET /Items?…&Fields=ArtistItems`, assert `len(ArtistItems) == N` | ⚠ extend `check-music-consumers.sh` | ⬜ pending |
| CONF-04 | N distinct artist entities in Music Assistant | D-22, D-25, **D-36** | API read-back | `music/tracks/library_items` → `artists[]` | ❌ **gated** — host down for maintenance | ⬜ blocked |
| CONF-04 | write side: what beets would actually emit (`artist`, `artists`) | D-23 *(amended by D-34)* | oracle | assert the beets fields the import would write on the sampled multi-artist release | ❌ W0 | ⬜ pending |
| CONF-04 | `PreferNonstandardArtistsTag` is enabled and **stays** enabled | **D-34** | assertion | `GET /Library/VirtualFolders` → assert the Music library's flag | ❌ W0 | ⬜ pending |
| CONF-05 | `preferred.countries` contains `GB` (**not** `UK`), `original_year`, `musicbrainz.extra_tags` | — | assertion | committed-config read-back | ❌ W0 | ⬜ pending |
| CONF-05 | a *Now!* volume prefers the UK release | D-28 | driven | **cannot** be `--pretend` — needs a real candidate lookup (`beet import -t` on a throwaway, or flask `preview`), reading the chosen candidate's `country` | ❌ W0 | ⬜ pending |
| CONF-06 | zero-diff against the committed expected tree | **D-33**, D-27 | oracle diff | `diff <(beet move -p …) 06-EXPECTED-TREE.txt` — **`beet move -p`, never `beet import --pretend`** | ❌ W0 | ⬜ pending |
| CONF-06 | `--pretend` proves `incremental` / `ignore` / grouping only | **D-33** | assertion | `beet import --pretend` on a throwaway `-c` overlay | ❌ W0 | ⬜ pending |
| — | three inboxes registered; **fail closed on fewer than three** | D-09 | log assertion | grep startup log for `Registering watchdog … for inboxes: [...]` | ❌ W0 | ⬜ pending |
| — | an inbox actually **fires** (registration ≠ firing) | D-09 | driven | one throwaway folder into `02-review`, wait ≥ 35 s (`debounce_before_autotag: 30`), confirm a preview task, remove | ❌ W0 | ⬜ pending |
| — | exactly two tagger definitions, **named and classed** | D-11 | assertion | revise `check-music-freeze.sh:793-801` | ⚠ revise in place | ⬜ pending |
| — | throwaway `-l` **and** `-c` overlay on every CLI-arm invocation | D-04 | assertion | `scripts/quick-health-check.sh`, beside the vendored-file drift block | ❌ W0 | ⬜ pending |
| — | **wrote nothing**, three layers | D-29 | assertion | (1) `docker inspect` mount `RW=false` on `/media`; (2) sha256 manifest over sampled source folders; (3) sha256 of `library.db` **and** `state.pickle` | ❌ W0 | ⬜ pending |
| — | rc6 did **not** install its own example config | research § rc6 bootstrap | log assertion | assert the `Copying default config to` line is **absent** from the startup log | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Each is owned by a named plan. ❌ in the map above means *scheduled in that plan*, not unowned.

| Artifact | Owning plan | Wave |
|----------|-------------|------|
| `scripts/check-beets-config.sh` — reads the **server-committed** config, asserts CONF-01/02/03/05 keys, distinguishes "could not look" from "correct" | **06-07** | 3 |
| `scripts/phase06-oracle.sh` — throwaway import + `beet move -p`, stable diffable path list, 9 class assertions, `--self-test` | **06-09** | 3 |
| `scripts/phase06-incremental-control.sh` — D-31's two-overlay negative control | **06-08** | 3 |
| `06-SAMPLE.md` (seeded draw) and `06-EXPECTED-TREE.txt` — both committed **before** any oracle run (D-26/D-27) | **06-05** | 2 |
| `scripts/check-music-freeze.sh` — tagger census to `expected=2, named` (D-11) + throwaway-`-l` assertion (D-04), in the same commit as `beets.md:1255` | **06-10** | 3 |
| `scripts/quick-health-check.sh` — drift block widened 3 → 4 (count, `case`, `DRIFT_EXPECT_*`, green line moved together) (D-03) | **06-10** | 3 |
| `scripts/check-music-consumers.sh` — per-consumer artist-entity check (D-22) on the argv-safe `jf_api`/`ma_api` helpers; D-34 flag assertion | **06-03**, **06-13** | 1, 4 |

- [ ] **No framework install.** Do not introduce pytest — this repo has no test framework by design.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Music Assistant artist-entity read-back | CONF-04 | **D-36** — MA (`8095`) and HA (`8123`) on `172.16.1.31` are down for maintenance (operator statement; probed closed twice on 2026-09-20). The check is written and automated, but must not run blind. | Task is `autonomous: false`. **Stop and confirm with the operator that MA is back online**, then run the automated check. If MA never returns, CONF-04 stays `OPEN` — it must not read as passed. |
| `PreferNonstandardArtistsTag` enablement | CONF-04 | **D-34** — a live-service config change on a 1,244-file library that **git does not capture**. | Set via Jellyfin library options, record in `stacks/selfhosted/arrs/beets.md`, then add the automated assertion so a silent UI revert is caught. |
| Jellyfin targeted scan | CONF-04 | D-24 — the safe and unsafe buttons sit next to each other. | Use `POST /Library/Media/Updated`. **Never** `POST /Items/{id}/Refresh?metadataRefreshMode=FullRefresh` or `POST /Library/Refresh`. Budget ≥ 90 s for `LibraryMonitorDelay = 60`. |

---

## Validation Sign-Off

- [ ] All tasks have an automated verify or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all ❌ references above
- [ ] No watch-mode flags
- [ ] Feedback latency < 120 s
- [ ] Every check fails closed, with "could not look" distinct from "nothing is wrong"
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
