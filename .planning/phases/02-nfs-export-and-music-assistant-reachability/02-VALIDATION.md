---
phase: 2
slug: nfs-export-and-music-assistant-reachability
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-29
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `02-RESEARCH.md` § Validation Architecture.

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

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/check-music-consumers.sh`
- **After every plan wave:** Run `bash scripts/check-music-consumers.sh && bash scripts/check-music-freeze.sh` — so a Phase 1 regression cannot hide behind a Phase 2 pass
- **Before `/gsd-verify-work`:** Full suite green, **plus** criterion 4b's negative control run once with its three pieces of evidence captured in SUMMARY.md. A green 4a without 4b is not sufficient — the race can pass by luck.
- **Max feedback latency:** 30 seconds
- **Standing:** fold the consumers check into `scripts/quick-health-check.sh` the way 01-09 folded in `check-music-freeze.sh`, so estate health covers CONS-01/03 from then on.

---

## Per-Task Verification Map

> Populated by `gsd-planner`. Every task must map to a row here or to a Wave 0 dependency below.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | | | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Success criterion → evidence map (from RESEARCH.md)

| Crit | Behaviour | Type | Automated command | Exists? |
|------|-----------|------|-------------------|---------|
| 1a | Export exists, is `ro`, restricted to `172.16.1.31`, no `no_root_squash` | integration | `ssh root@172.16.1.158 'exportfs -v'` parsed in `check-music-consumers.sh` | ❌ Wave 0 |
| 1b | Terraform re-apply is clean | integration | `cd infra && terraform apply -auto-approve && terraform plan -detailed-exitcode` (exit 0 = no changes) | ❌ Wave 0 |
| 1c | Export served from the host, not LXC 100 | integration | `ssh root@172.16.1.158 'systemctl is-active nfs-server'` **and** `ssh root@172.16.1.159 'systemctl is-active nfs-server \|\| echo absent'` | ❌ Wave 0 |
| 1d | Visible from the NUC | integration | `showmount -e 172.16.1.158` (falls back to the mount attempt if `showmount` is absent on HAOS) | ❌ Wave 0 |
| 1e | NFSv4 actually negotiated | integration | `findmnt -no FSTYPE,OPTIONS <mountpoint>` → expect `nfs4` and `vers=4.x` | ❌ Wave 0 |
| 2 | A write from the NUC fails **at the export layer** | integration | Stage 4b: hand `mount -o rw` then `touch`; assert EROFS | ❌ Wave 0 |
| 3 | Three albums under the correct album artist within one sync cycle | integration | `music/sync` then `music/albums/library_items`, compared against `pilot-albums.txt` | ❌ Wave 0 |
| 4a | Positive reboot: mount active, albums present, no intervention | manual trigger + automated assert | `ha host reboot`, wait, then `check-music-consumers.sh` | ❌ Wave 0 |
| 4b | Negative control: the race actually fires and recovers unattended | manual trigger + automated assert | assert on `emergency/music` in `mount`, the `read-only fallback` log line, MA's `Aborting sync` line, then unattended recovery | ❌ Wave 0 |
| 5 | Winning route + losing route's failure symptom recorded in PROJECT.md; the current mount-route assertion corrected | doc assert | `grep -q 'Key Decision' .planning/PROJECT.md` plus a manual read | manual-only |
| B-1 | Jellyfin unaffected | integration | `bash scripts/check-music-freeze.sh` exits with the Phase 1 closure code; plus a Jellyfin API library-count check | partially exists |

---

## Wave 0 Requirements

- [ ] `scripts/check-music-consumers.sh` — covers CONS-01, CONS-02, CONS-03; exit-code contract in the header
- [ ] `.planning/phases/02-nfs-export-and-music-assistant-reachability/pilot-albums.txt` — the three albums as `Album|Album Artist`, chosen from content that is *already correctly tagged*
- [ ] `~/.claude/secrets/ma-deercrest.env` — `MA_URL`, `MA_TOKEN_FILE`, and the credentials used to mint the token (outside the repo — the repo is public)
- [ ] A one-line addition to `scripts/quick-health-check.sh` invoking the consumers check
- [ ] Framework install: **none** — bash + `jq` + `curl` only

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| NUC reboot (criteria 4a/4b) | CONS-03 | Rebooting the HA/NUC host cannot be automated safely from CI — it is also the estate's second Tailscale subnet router | `ha host reboot`, wait for the host to return, then run `bash scripts/check-music-consumers.sh` with no manual mount intervention |
| Negative control that the mount-timing race actually fired (4b) | CONS-03 | Requires deliberately provoking the race and reading log lines that only exist during the window | Capture three pieces of evidence: `emergency/music` present in `mount`, the `read-only fallback` log line, MA's `Aborting sync` line — then confirm unattended recovery |
| PROJECT.md Key Decision prose is correct and the losing route's symptom is named (criterion 5) | CONS-01 | Prose correctness is not machine-checkable; `grep` can only prove the section exists | Read the Key Decision entry; confirm the winning route, the losing route's failure symptom, and that PROJECT.md's prior mount-route assertion is corrected |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
