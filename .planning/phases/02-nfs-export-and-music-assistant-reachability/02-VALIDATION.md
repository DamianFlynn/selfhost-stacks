---
phase: 2
slug: nfs-export-and-music-assistant-reachability
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-29
updated: 2026-08-29
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `02-RESEARCH.md` § Validation Architecture, reconciled against `02-CONTEXT.md`
> (which supersedes it on the pilot-album fixture and the secrets location).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | **None.** There is no test framework and no Python in the tree. The estate convention is bash audit scripts under `scripts/` with a documented exit-code contract. |
| **Config file** | none |
| **Quick run command** | `bash scripts/check-music-consumers.sh` |
| **Full suite command** | `bash scripts/check-music-consumers.sh && bash scripts/check-music-freeze.sh` |
| **Estimated runtime** | ~30 seconds (four SSH round-trips plus three MA API calls) |

**Exit-code contract** — inherit `scripts/check-music-freeze.sh` exactly, and state it in the file
header: default mode increments `FAILURES` per red finding and exits non-zero; `--baseline` prints
everything and always exits 0. The estate's older scripts exit 0 on findings, and that silence is
what hid the `created`-state blind spot for six weeks.

**Three branches, not two** (`check-music-freeze.sh:539-549`): `--baseline` exits 0 *after* printing
the summary, `FAILURES>0` exits 1, and a usage error exits 2. RESEARCH.md's
`exit $(( FAILURES > 0 ? 1 : 0 ))` skeleton cannot express `--baseline` and is not the estate shape.

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/check-music-consumers.sh`
- **After every plan wave:** Run `bash scripts/check-music-consumers.sh && bash scripts/check-music-freeze.sh` — so a Phase 1 regression cannot hide behind a Phase 2 pass
- **Before `/gsd-verify-work`:** Full suite green, **plus** criterion 4b's negative control run once with its three pieces of evidence captured in SUMMARY.md. A green 4a without 4b is not sufficient — the race can pass by luck.
- **Max feedback latency:** 30 seconds
- **Standing:** fold the consumers check into `scripts/quick-health-check.sh` the way 01-09 folded in `check-music-freeze.sh`, so estate health covers CONS-01/03 from then on. (Plan 02-09 Task 1.)

**Note on ordering:** until plan 02-04 creates `check-music-consumers.sh`, and until plan 02-06 pins
the provider instance id into it, the per-task sampling command is
`bash scripts/check-music-consumers.sh --baseline` (always exits 0). A non-`--baseline` run is only
expected to exit 0 from plan 02-07 Task 1 onward. Plan 02-06 Task 2 deliberately records an
**exit 1** as the correct intermediate state — sections 0-2 green, 3-5 red — so the progression is
auditable and no assertion gets softened to manufacture a green run.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-T1 | 02-01 | 1 | CONS-01 | T-02-06, T-02-10, T-02-SC | No competing export table; package provenance from a Debian archive | integration | `ssh root@172.16.1.158 'zfs list -H -o mounted …; mountpoint -q …; test -z "$(ls -A /etc/exports.d/)"'` | ✅ (probe only) | ⬜ pending |
| 02-01-T2 | 02-01 | 1 | CONS-01 | T-02-06 | Drift cannot be swept into this phase's apply | integration | `cd infra && terraform plan -detailed-exitcode` | ✅ | ⬜ pending |
| 02-01-T3 | 02-01 | 1 | CONS-02, CONS-03 | T-02-04, T-02-05 | NUC source address measured, not assumed | integration | `ssh root@172.16.1.159 'curl -s -o /dev/null -w %{http_code} http://172.16.1.31:8095/info'` ∈ {200,401,403} | ✅ (probe only) | ⬜ pending |
| 02-01-T4 | 02-01 | 1 | CONS-02, CONS-03 | T-02-05 | MA `/setup` completed at a blocking operator checkpoint, not autonomously; account name recorded, password and token never | manual trigger + automated assert | `ssh root@172.16.1.159 'curl -s -o /dev/null -w %{http_code} http://172.16.1.31:8095/info'` ∈ {200,401,403}; then `auth/login` → `config/providers` HTTP 200 | ✅ (probe only; conditional — fires only if 02-01-T3 found no MA account) | ⬜ pending |
| 02-02-T1 | 02-02 | 2 | CONS-01 | T-02-08 | Tailnet exclusion recorded in the variable description | static | `cd infra && terraform fmt -check variables.tf && terraform validate` | ❌ → created here | ⬜ pending |
| 02-02-T2 | 02-02 | 2 | CONS-01 | T-02-01, T-02-02, T-02-03, T-02-06, T-02-11 | `ro`+`all_squash`+`anonuid` interpolated; apply fails on `no_root_squash` | static | `cd infra && terraform validate && grep -q 'anonuid=${var.apps_uid}' nfs-music-export.tf && ! grep -qE '^[^#]*fsid=' nfs-music-export.tf` | ❌ → created here | ⬜ pending |
| 02-02-T3 | 02-02 | 2 | CONS-01 | T-02-12 | Temp export invisible unless deliberately enabled | static | `cd infra && terraform plan -detailed-exitcode` shows exactly 1 to add | ❌ → created here | ⬜ pending |
| 02-03-T1 | 02-03 | 3 | CONS-01 | T-02-14 | Clean re-apply (criterion 1b) | integration | `cd infra && terraform apply -auto-approve && terraform plan -detailed-exitcode` (exit 0) | ✅ | ⬜ pending |
| 02-03-T2 | 02-03 | 3 | CONS-01 | T-02-01, T-02-02, T-02-06, T-02-13 | Export asserted in the live kernel table; M1 proven by unmount | integration | `ssh root@172.16.1.158 'exportfs -v'` asserts `ro`/`all_squash`/`anonuid=568`/`mountpoint`, rejects `no_root_squash` and `*(`/`/NN(` | ✅ | ⬜ pending |
| 02-03-T3 | 02-03 | 3 | CONS-01 | T-02-08 | Jellyfin and the Phase 1 harness measured unchanged | integration | `ssh root@172.16.1.159 'bash …/check-music-freeze.sh'` exit == Phase 1 closure code | ✅ | ⬜ pending |
| 02-04-T1 | 02-04 | 2 | CONS-02, CONS-03 | T-02-05, T-02-15 | Tokens 0600 root, via stdin, never in the repo | integration | `stat -c '%a %U'` == `600 root` on both; authenticated `config/providers` → HTTP 200 | ❌ → created here | ⬜ pending |
| 02-04-T2 | 02-04 | 2 | CONS-02 | — | Albums pre-verified before use as a gate | integration | `test -d` for all three album paths from LXC 100 | ✅ (QUAL-01 snapshot) | ⬜ pending |
| 02-04-T3 | 02-04 | 2 | CONS-01, CONS-02, CONS-03 | T-02-07, T-02-18, T-02-05 | Read-only by contract; three-branch exit; no fixture file | integration | `bash -n` + `--baseline` exit 0 + `--bogus-flag` exit 2 + `git grep -E 'Bearer [A-Za-z0-9._-]{20,}'` empty | ❌ → **Wave 0 artifact, created here** | ⬜ pending |
| 02-05-T1 | 02-05 | 4 | CONS-01, CONS-02 | T-02-23, T-02-08 | Mount is real, not the emergency stub; NFSv4 asserted | integration | `ha mounts info --raw-json` → `.state=="active"`; `mount \| grep -c emergency/music` == 0; `findmnt -no FSTYPE,OPTIONS` contains `nfs4`,`vers=4` | ✅ | ⬜ pending |
| 02-05-T2 | 02-05 | 4 | CONS-01 | T-02-03, T-02-22 | **Criterion 2** — refusal at the export, not the client | integration | `mount -t nfs -o rw …; touch` → `Read-only file system`; then `umount`; `find … -name '_ro_probe*'` == 0 | ✅ | ⬜ pending |
| 02-05-T3 | 02-05 | 4 | CONS-02 | T-02-23 | Bytes proven to traverse the mount | integration | `sha256sum` on atlantis == `sha256sum` through the NUC mount, ×3 | ✅ | ⬜ pending |
| 02-06-T1 | 02-06 | 5 | CONS-02 | T-02-24, T-02-25, T-02-19 | `content_type: music` and `folder_name` proven by read-back | integration | `config/providers` → filesystem provider with `available == true`; `find … -name '*.txt' -newermt` == 0 | ✅ | ⬜ pending |
| 02-06-T2 | 02-06 | 5 | CONS-02 | T-02-16, T-02-26, T-02-27 | Assertions filter by instance id, not display name | integration | `! grep -qi 'not yet pinned' scripts/check-music-consumers.sh`; non-baseline run exits **1** with 0-2 green, 3-5 red (expected intermediate) | ✅ | ⬜ pending |
| 02-07-T1 | 02-07 | 6 | CONS-02 | T-02-16, T-02-03 | **Criterion 3** — exact match on album *and* album artist | integration | `bash scripts/check-music-consumers.sh` exits **0** (no `--baseline`) | ✅ | ⬜ pending |
| 02-07-T2 | 02-07 | 6 | CONS-02 | T-02-28, T-02-12 | `folder_name` proven to fire; control never under `/media/Music` | integration | `exportfs -v \| grep -cE '^/mnt/tank'` == 2; `config/providers` filesystem count >= 2; control album `artists[0].name` == folder name | ✅ | ⬜ pending |
| 02-07-T3 | 02-07 | 6 | CONS-02 | T-02-29, T-02-30, T-02-31 | Teardown provable on both sides (D-46) | integration | `exportfs -v \| grep -cE '^/mnt/tank'` == 1; `terraform plan -detailed-exitcode` exit 0; filesystem provider count == 1 | ✅ | ⬜ pending |
| 02-08-T1 | 02-08 | 7 | CONS-03 | T-02-05, T-02-37 | M4 gated on a *verified* `rest_command`; token as `!secret` only | integration | `ha core check` valid; `grep -cE 'Bearer [A-Za-z0-9._-]{20,}' /config/configuration.yaml` == 0 | ❌ (off-repo, NUC) | ⬜ pending |
| 02-08-T2 | 02-08 | 7 | CONS-03 | T-02-34, T-02-33 | **Criterion 4a** — survives reboot with no intervention | manual trigger + automated assert | `ha host reboot`, then `bash scripts/check-music-consumers.sh` exits 0 | ✅ | ⬜ pending |
| 02-08-T3 | 02-08 | 7 | CONS-03 | T-02-32, T-02-35, T-02-36 | **Criterion 4b** — race fires, MA preserves, recovery unattended | manual trigger + automated assert | assert `emergency/music` in `mount`, `read-only fallback` log line, MA `Aborting sync` line; then `check-music-consumers.sh` exit 0 + `systemctl is-active nfs-server` == active | ✅ | ⬜ pending |
| 02-09-T1 | 02-09 | 8 | CONS-01, CONS-02, CONS-03 | T-02-37, T-02-39 | Standing coverage; empty output → UNKNOWN, never a silent pass | integration | `bash -n scripts/quick-health-check.sh && bash scripts/quick-health-check.sh` exits 0 with both blocks green | ✅ | ⬜ pending |
| 02-09-T2 | 02-09 | 8 | CONS-01 | T-02-05, T-02-38, T-02-04 | **Criterion 5** — route recorded, prior assertion corrected, no credential in docs | doc assert | `grep -q 'nfs-music-export.tf' NETWORK.md && grep -q '^## Phase 2' stacks/selfhosted/arrs/beets.md && git grep -E 'Bearer [A-Za-z0-9._-]{20,}'` empty | ✅ | ⬜ pending |
| 02-09-T3 | 02-09 | 8 | CONS-01, CONS-02, CONS-03 | T-02-40 | No criterion recorded as proven on weaker evidence than specified | manual + automated | `bash scripts/quick-health-check.sh` exit 0; `check-music-consumers.sh` exit 0; `check-music-freeze.sh` exit 0 | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Success criterion → evidence map (from RESEARCH.md, with the plan that produces it)

| Crit | Behaviour | Type | Automated command | Produced by |
|------|-----------|------|-------------------|-------------|
| 1a | Export exists, is `ro`, restricted to the NUC, no `no_root_squash` | integration | `ssh root@172.16.1.158 'exportfs -v'` parsed in `check-music-consumers.sh` | 02-03-T2 |
| 1b | Terraform re-apply is clean | integration | `cd infra && terraform apply -auto-approve && terraform plan -detailed-exitcode` (exit 0 = no changes) | 02-03-T1 |
| 1c | Export served from the host, not LXC 100 | integration | `ssh root@172.16.1.158 'systemctl is-active nfs-server'` **and** `ssh root@172.16.1.159 'systemctl is-active nfs-server \|\| echo absent'` | 02-03-T2 |
| 1d | Visible from the NUC | integration | `showmount -e 172.16.1.158` (falls back to the mount attempt if `showmount` is absent on HAOS) | 02-05-T1 |
| 1e | NFSv4 actually negotiated | integration | `findmnt -no FSTYPE,OPTIONS <mountpoint>` → expect `nfs4` and `vers=4.x` | 02-05-T1 |
| 2 | A write from the NUC fails **at the export layer** | integration | Stage 4b: hand `mount -o rw` then `touch`; assert EROFS | 02-05-T2 |
| 3 | Three albums under the correct album artist within one sync cycle | integration | `music/sync` then `music/albums/library_items`, exact-matched against the album set pinned in `check-music-consumers.sh` (D-09) | 02-07-T1 |
| 3′ | The `folder_name` fallback actually fires (D-03) | integration | Control album on the temp export returns `artists[0].name` == its folder name | 02-07-T2 |
| 4a | Positive reboot: mount active, albums present, no intervention | manual trigger + automated assert | `ha host reboot`, wait, then `check-music-consumers.sh` | 02-08-T2 |
| 4b | Negative control: the race actually fires and recovers unattended | manual trigger + automated assert | assert on `emergency/music` in `mount`, the `read-only fallback` log line, MA's `Aborting sync` line, then unattended recovery | 02-08-T3 |
| 5 | Winning route + losing route's failure symptom recorded in PROJECT.md; the current mount-route assertion corrected | doc assert | `grep` for the Key Decision rows plus a manual read | 02-09-T2, 02-09-T3 |
| B-1 | Jellyfin unaffected | integration | `bash scripts/check-music-freeze.sh` exits with the Phase 1 closure code; plus a Jellyfin API library-count check | 02-03-T3, 02-04-T3 |

---

## Wave 0 Requirements

All Wave 0 items are assigned to **plan 02-04 (Wave 2)**, which is why 02-04 sits alongside the
Terraform authoring rather than after the export is live — it is eligible to run in parallel with
02-02, and correct in either order. Its own verification uses `--baseline`, so it does not depend on
anything the export provides.

- [ ] `scripts/check-music-consumers.sh` — covers CONS-01, CONS-02, CONS-03; exit-code contract in the header, matching `check-music-freeze.sh:31-42` / `:539-549` (three branches: `--baseline` exits 0 after the summary, `FAILURES>0` exits 1, `exit 2` for usage errors) → **02-04-T3**
- [ ] The three pilot albums **pinned in `scripts/check-music-consumers.sh`** — path, expected album and album artist, keyed on the QUAL-01 `audio_md5` (CONTEXT.md D-09). *No external `pilot-albums.txt`* — RESEARCH.md § Validation Architecture proposed one, but CONTEXT.md D-09 supersedes it, and Phase 1 committed zero non-`.md` artifacts under `.planning/`. → **02-04-T2, 02-04-T3**
- [ ] MA long-lived token at `/mnt/fast/secrets/` on LXC 100, `0600` (CONTEXT.md D-39). *Not* `~/.claude/secrets/ma-deercrest.env` — RESEARCH.md's location is superseded by D-39. → **02-04-T1**
- [ ] Jellyfin API key, newly minted and purpose-named (`music-consumers-audit`), same location (CONTEXT.md D-40) → **02-04-T1**
- [ ] Provider instance id pinned into the script so assertions filter by identity rather than display name (D-30) → **02-06-T2**
- [ ] A one-line addition to `scripts/quick-health-check.sh` invoking the consumers check — copy the `:63-91` fold-in block verbatim, including `MUSIC_RC=$?` captured before any pipe, `$'\033'` ANSI stripping (the script runs on macOS), and empty-output → `UNKNOWN` + `EXIT_CODE=1` → **02-09-T1**
- [ ] Framework install: **none** — bash + `jq` + `curl` only

**Where the script runs** is resolved in plan 02-04 Task 3 and stated in the file's `# Where it runs:`
header block: **host-resident on LXC 100**. Jellyfin (`192.168.90.31:8096` on `t3_proxy`) is reachable
only from LXC 100 and D-39/D-40 place both tokens there, which is close to decisive. The one pull the
other way — the NUC SSH key exists only on the workstation — is handled by an `HA_ROUTE` variable
following the `ZFS_ROUTE` precedent (`check-music-freeze.sh:123-131`): the `ha mounts info` assertion
runs when `HA_SSH_KEY` is available and is otherwise skipped with a `warn()`, while the **hard**
assertions use MA-side equivalents that always run. That is not a weakening — if the Supervisor
emergency bind is in place, `/media/music` is empty, MA's scan finds zero files, and the album-count
and exact-match assertions fail. The key is deliberately *not* replicated to LXC 100.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| NUC reboot (criteria 4a/4b) | CONS-03 | Rebooting the HA/NUC host cannot be automated safely — it is also the estate's second Tailscale subnet router, and failover is sticky (never fails back on its own) | `ha host reboot`, wait for the host to return, then run `bash scripts/check-music-consumers.sh` with no manual mount intervention (02-08-T2) |
| Negative control that the mount-timing race actually fired (4b) | CONS-03 | Requires deliberately provoking the race and reading log lines that only exist during the window, plus a ~900 s unattended wait | Capture three pieces of evidence: `emergency/music` present in `mount`, the `read-only fallback` log line, MA's `Aborting sync` line — then confirm unattended recovery (02-08-T3) |
| MA provider initial creation, if the config flow cannot be driven headlessly | CONS-02 | The flow's intermediate step ids are runtime values, not documented outside the running server | Run `/api-docs/commands.json` discovery first; fall back to the GUI click path for the initial creation only, keeping everything downstream headless (02-06-T1, D-31) |
| PROJECT.md Key Decision prose is correct and the losing route's symptom is named (criterion 5) | CONS-01 | Prose correctness is not machine-checkable; `grep` can only prove the section exists | Read the Key Decision entries; confirm the winning route, the losing route's failure symptom, and that PROJECT.md's prior mount-route assertion is corrected rather than supplemented (02-09-T2) |
| MA `/setup`, if Music Assistant has no admin user at all (02-01-T4) | CONS-02, CONS-03 | MA's first-run onboarding cannot be driven from the API without an existing credential — that absence is the gap. Conditional: fires only when 02-01-T3 records no account | Open `http://172.16.1.31:8095/setup`, create the admin account, then Claude mints the long-lived token over `auth/login` → `auth/token/create` and writes it per D-39 (02-01-T4, D-43, D-53) |
| Operator sees the three albums in Music Assistant (closure gate) | CONS-02 | Criterion 3 is ultimately about what a person sees; this project exists because pipelines were declared working three times and were not | Open Music Assistant, confirm the three pinned albums appear under the correct album artists (02-09-T3, D-55) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies — 27/27 tasks carry an `<automated>` command
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references — assigned to 02-04 (script, albums, credentials) and 02-06 (instance id)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Note on the four `checkpoint:*` tasks** (02-01-T2, 02-01-T4, 02-08-T2, 02-08-T3): each carries both an
`<automated>` command and a `<human-check>` or `<resume-signal>`. The automated half is what the
harness samples; the human half is the blocking gate D-53 requires. Neither substitutes for the other.

**Approval:** planned 2026-08-29 by `gsd-planner`; execution status pending.
