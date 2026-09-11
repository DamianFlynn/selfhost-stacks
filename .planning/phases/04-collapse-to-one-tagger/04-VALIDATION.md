---
phase: 4
slug: collapse-to-one-tagger
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-11
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `04-RESEARCH.md` § *Validation Architecture*, with the operator's post-research
> rulings of 2026-09-11 (recorded in `04-CONTEXT.md` § *Operator rulings after research*) applied.

**This phase deletes things, so its proofs are absences — and an absence is the easiest thing to
pass by accident.** Every census and drift check below must keep "could not look" (UNKNOWN, exit 1)
distinct from "nothing is there" (green), and each new check's **first run happens before the
deletion it guards**, so that run is its own driven negative control: it must fail, naming each
retired path, or the check is not measuring anything.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Estate bash health checks with driven negative controls, plus `--self-test` modes. **No pytest/bats in this repo and none is warranted** |
| **Config file** | none — checks are self-contained scripts; see Wave 0 |
| **Quick run command** | `bash scripts/quick-health-check.sh` (workstation; folds in `check-music-freeze.sh` via `ssh -n`) |
| **Full suite command** | quick run + `bash scripts/check-renovate.sh` + `renovate-config-validator --strict --no-global renovate.json5` + (on LXC 100) `bash scripts/check-music-freeze.sh` |
| **Estimated runtime** | ~60 s quick · ~120 s full (`REMOTE_TIMEOUT` default 120 s bounds every remote command) |

---

## Sampling Rate

- **After every task commit:** `renovate-config-validator --strict --no-global renovate.json5` for
  any `renovate.json5` touch; `bash -n` + the script's `--self-test` for any script touch;
  `docker compose -f <file> config --quiet` for any compose touch.
- **After every plan wave:** `bash scripts/quick-health-check.sh` from the workstation, **after** the
  host `git pull` in `/mnt/fast/stacks` (the host was at `3327dcf` vs origin `4604764` on
  2026-09-11 — a check run against a stale checkout proves nothing about the repo).
- **Before `/gsd-verify-work`:** full suite green **plus** the D-12 job evidence **plus** the
  executed D-21 census run whose counters are pasted into `stacks/selfhosted/arrs/beets.md` (D-25).
- **Max feedback latency:** 120 s.

---

## Per-Task Verification Map

Task IDs are assigned by the planner; rows are keyed by success criterion / requirement / decision
and each plan task must cite the row it satisfies.

| Row | Requirement | Behavior | Test Type | Automated Command (what proves it) | "Could not look" looks like | File Exists | Status |
|-----|-------------|----------|-----------|-------------------------------------|-----------------------------|-------------|--------|
| C1-a | TAGR-03 | Exactly one tagger definition in deployable stacks | static | `git ls-files stacks \| xargs grep -lE '^\s*image:\s*(lscr\.io/linuxserver/beets\|sentriz/wrtag\|ghcr\.io/terry90/soulbeet\|metasauce/beets-flask)'` → exactly `stacks/selfhosted/arrs/beets/beets.yaml`; `git ls-files \| grep -E 'soulbeet\|selfhosted/music/'` → empty | n/a (git) | ❌ W0 (census section) | ⬜ pending |
| C1-b | TAGR-04 | Issue #306 closed with evidence | manual/API | `gh issue view 306 --json state,comments` → `CLOSED`, closing comment cites the D-26 facts | gh auth failure → UNKNOWN, never "closed" | n/a | ⬜ pending |
| C1-c | TAGR-03 (OQ8) | Survivor include line resolves | static | `grep -c '^#  - beets/beets.yaml$' stacks/selfhosted/arrs/compose.yaml` → 1; `grep -c '^#  - beets.yaml$'` → 0; `grep -c 'soulbeet' stacks/selfhosted/arrs/compose.yaml` → 0 | n/a | ✅ | ⬜ pending |
| C2-a | TAGR-03 | wrtag rule gone; beets rules valid; config valid | static | `grep -c 'sentriz/wrtag' renovate.json5` → 0; `renovate-config-validator --strict --no-global renovate.json5` → exit 0; **negative control**: a scratch copy with `"automerg": false` → exit 1 | validator absent → `check-renovate.sh` prints yellow UNVALIDATED, which is **not** a pass | ✅ route · ❌ `--no-global` fix | ⬜ pending |
| C2-b | TAGR-03 (OQ4) | Survivor rule is effective, not inert | static + observation | two-rule shape present (versioning-only rule, then manual-review rule) and validates `--strict` in both modes; post-merge, Renovate proposes `2.13.1-ls350` — **expected, recorded, not drift** | Renovate has not run since the merge → "not yet observed", never "working" | ❌ | ⬜ pending |
| C2-c | TAGR-03 | Renovate accepted the config | observation | Dependency Dashboard #3 no longer lists soulbeet or `music/wrtag.yaml`; no "Action Required" issue opened | Renovate not yet run → "not yet observed" | manual | ⬜ pending |
| C3-a | TAGR-04 | Beets call stripped, guard untouched | static | `grep -cE '^\s*beet ' <vendored audio.bash>` → 0; guard lines 27–35 byte-identical to the live `fdcddca2…` copy's; only line 285 differs (`diff` shows one removed line) | n/a | ❌ (file not yet vendored) | ⬜ pending |
| C3-b | TAGR-04 (D-09) | SABnzbd boots and post-processes with `:ro` mounts | e2e | after recreate: `docker logs sabnzbd` shows `[custom-init] scripts_init.bash: exited 0`; `docker inspect` shows both vendored mounts `RW=false`; HTTP 200 on `:8084`; sha256 of both files unchanged | container not running → **FAIL**, not UNKNOWN | manual | ⬜ pending |
| C3-c | TAGR-04 (D-12) | A real music job completes with no tagger | e2e | SAB history row `Completed` with `script_line` equal to the **baseline** `Exit(1): chmod …` (F8 — pre-existing, not a regression); `find …/scripts -newer <stamp>` shows no `library.blb`/`*.bak`/`beets.log`/`beets-match`; `ffprobe` on the job's files shows no beets-written `MUSICBRAINZ_*` tags; `Audio.txt` shows exactly the two pre-declared residual lines (OQ5) | no job arrived in the window → criterion **open**, not passed | ❌ W0 (evidence checklist) | ⬜ pending |
| C3-d | TAGR-04 (D-13) | Vendored-file drift is detected | health | `quick-health-check.sh` drift block: exit 0 green naming both vendored files; **driven control**: override the expected hash → exit 1 naming the file and both hashes | ssh empty → UNKNOWN; RC 124 → UNKNOWN (timeout); RC≠0 → could not look | ❌ W0 | ⬜ pending |
| C4-a | TAGR-05 (OQ1) | Every remaining beets config declares musicbrainz | static + live | repo: every beets config's `plugins:` contains `musicbrainz` (sabnzbd `beets-config.yaml` **and** the newly vendored survivor config); host: same grep over the census list; `config.yaml.old` absent | host unreachable → UNKNOWN | ❌ W0 | ⬜ pending |
| C4-b | TAGR-05 (D-16/D-20, OQ3) | Probe: broken → 0 MB candidates; fixed → ≥1 | e2e | probe on `Garth Brooks-Scarecrow-CD-FLAC-2001-FLACME-xpost` (presence re-asserted at execution) in **MB-only mode** (no Discogs token): NDJSON `jq '[.[]\|select(.source=="MusicBrainz")]\|length'` → 0 then ≥1; `beet version` plugin lines differ; hand-read `import -t` shows a MusicBrainz candidate list | HTTP 503 from musicbrainz.org → re-run, **never** read as zero | ❌ W0 (MB-only probe mode) | ⬜ pending |
| C5-a | TAGR-03/04 (D-21/D-25, OQ2, OQ6) | tagger defs = 1; beets DBs = 1 (the fresh survivor `library.db`); retired DBs absent; rw-on-Music on non-tagger containers = 0, Jellyfin (D-21 exception) printed separately; all container states counted | health | `check-music-freeze.sh` new census section + summary counters, widened into `quick-health-check.sh`. Retired paths include both old survivor DBs (`library.db`, `musiclibrary.blb`), sabnzbd `scripts/library.blb` + `.bak`, sabnzbd `.config/beets/`, `media/wrtag/`. **Driven control:** first run **before** deletion fails naming each retired path; `RETIRED_DB_PATHS` override at an existing scratch file → exit 1 | docker unavailable → counters print UNKNOWN, exit 1 (DEF-03-11) | ❌ W0 | ⬜ pending |
| C5-b | D-04 | Every deleted DB was fenced first | live | each deleted DB has a `MANIFEST.txt` line with sha256 and `integrity_check ok` **before** its `rm`; `wrtag.db` specifically (F2 — not in the Phase 1 fence) copied via `sqlite3 .backup` | fence unreadable → refuse the delete | ❌ | ⬜ pending |
| C5-c | D-04 | Retired runtime state gone | live | `docker ps -a --format '{{.Names}}' \| grep -ciE 'wrtag\|soulbeet'` → 0; `test ! -e` on each deleted path | — | covered by C5-a | ⬜ pending |
| C5-d | OQ7 | wrtag DNS record removed | live | `dig +short wrtag.deercrest.info @1.1.1.1` → empty; Cloudflare API list for the name → 0 records; token read host-side, never on argv | dig/API failure → UNKNOWN | manual | ⬜ pending |
| D-22 | — | `check-renovate.sh` survives empty inputs; line 157 no longer inverted | unit-ish | PATH-stubbed `git` with empty `branch -r` → "✅ No pending Renovate PRs", exit 0; empty postgres/redis sets → counts 0, exit 0 | — | ❌ W0 (stub harness, 02.1-08 precedent) | ⬜ pending |
| D-23 | — | WAV write works, other frames intact, IPRD disagreement surfaced | unit | `docker run --rm --entrypoint python3 -v <scratch>:/w lscr.io/linuxserver/beets:2.13.1-ls349 /w/normalise-dj-tags.py --self-test` → exit 0; old `easy=True` path → self-test exit 1 | image absent → refuse, never pull silently | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/check-music-freeze.sh` — all-states census section + summary counters +
      `RETIRED_DB_PATHS` / `SURVIVOR_DB` env overrides (C5-a)
- [ ] `scripts/quick-health-check.sh` — drift block for both vendored files; selector widened to the
      new counters (C3-d, C5-a)
- [ ] `scripts/spike03-discogs-probe.py` — MB-only mode with no token and no identity probe (C4-b)
- [ ] `scripts/normalise-dj-tags.py` — `--self-test` with three synthetic WAVs (D-23)
- [ ] `scripts/check-renovate.sh` — `--no-global`; PATH-stub control for line 157 (C2-a, D-22)
- [ ] D-12 evidence checklist naming the two expected `Audio.txt` lines and the baseline Exit(1) (C3-c)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| A real SABnzbd music job completes without a tagger | TAGR-04 (D-12) | Needs a real download; organic jobs arrive about every 1–5 days | Human checkpoint: trigger a Lidarr search **or** wait for the next organic job; never script SAB with an API key on argv. Collect C3-c evidence from one stamp |
| SABnzbd boots with `:ro` vendored mounts | TAGR-04 (D-09) | LinuxServer boot-time ownership passes are unproven against `:ro` (research assumption A1) | Recreate once with both files `:ro`; if EROFS lines appear but the container is healthy, keep `:ro` and record the lines |
| Issue #306 closed | TAGR-04 | Closure is an operator-visible act on GitHub | `gh issue close 306` with the D-26 facts in the comment; verify with C1-b |
| Renovate accepted the edited config | TAGR-03 | Only observable after Renovate's next run | Check Dependency Dashboard #3 and for an ls350 PR; state "not yet observed" if it has not run |
| wrtag DNS record removed | OQ7 | Cloudflare change from LXC 100 with Traefik's token | Remove host-side, then C5-d |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120 s
- [ ] Every census/drift check's first run is before the deletion it guards, and fails
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
