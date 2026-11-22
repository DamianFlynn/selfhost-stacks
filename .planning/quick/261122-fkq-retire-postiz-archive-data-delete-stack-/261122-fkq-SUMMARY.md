---
phase: quick-261122-fkq
plan: 01
status: complete
subsystem: stacks/postiz (retired)
tags: [retirement, postiz, zernio, archive]
requirements: [QUICK-261122-fkq]
key-files:
  deleted:
    - stacks/selfhosted/postiz/compose.yaml
    - stacks/selfhosted/postiz/postiz.yaml
    - stacks/selfhosted/postiz/README.md
    - stacks/selfhosted/wrappers/postiz.app.yaml
  modified:
    - renovate.json5
    - scripts/pg-migrate.sh
    - STANDARDS.md
    - BACKLOG.md
    - .planning/plans/service-classification.plan.md
decisions:
  - "Postiz retired 2026-11-22: self-hosted Postiz cannot connect a personal LinkedIn profile (gitroomhq/postiz-app#1582). Social posting moves to Zernio (SaaS)."
completed: 2026-11-22
---

# Quick 261122-fkq: Retire Postiz Summary

Postiz appdata was archived to tank and snapshotted first. After that, the stack, its wrapper, the Renovate rule and the pg-migrate target were deleted. The deletion is deployed to origin/main and to LXC 100, and the Docker bind volumes are gone. The appdata files are untouched.

**DEPLOY_SHA:** `12f39e46da46ced4b29377ac7cd56a2bda0b0385` (`12f39e46`). origin/main and the host checkout `/mnt/fast/stacks` are both at this commit. The push went through first time, with no race.

## T1: Archive (atlantis, real root)

| Item | Value |
|---|---|
| Backing | `fast/appdata/postiz` is its **own ZFS dataset** (14.3M used/refer) |
| Snapshot | `fast/appdata/postiz@retire-postiz-20261122`, confirmed by `zfs list -t snapshot` |
| Archive | `/mnt/tank/backups/retired-stacks/postiz-appdata-20261122.tar.gz` (`/mnt/tank/backups` is on `tank/backups`) |
| sha256 | `42c5aa5603998a121127f71ef6d560530b96decde2388e006ba836e535b88ea0` |
| Size | 7,919,241 bytes |
| Mode | `-rw------- root root`. `chmod 600` worked (no EPERM) |
| `gzip -t` | GZIP_OK |
| Entries | 1,620 tar entries = PRE_COUNT 1,620 = post-archive count 1,620 (no difference) |
| `postiz/postgres/` entries | 1,615 |
| T1 verify | `T1_OK`, ssh_rc=0 (also re-run as the T2 step-0 gate) |
| Terraform fence | `INFRA_CLEAN`. `git hash-object infra/lxc-selfhost.tf` = `07d15de290abbf80042418efa683fec8ba136a14`, the same before and after |

Also archived: `/mnt/tank/backups/retired-stacks/postiz-workstation-env-20261122/` (dir 700, files 600). It holds `env` and `env.backup`, the gitignored workstation copies, plus `host-lxc100-env`, the LXC 100 `.env` that survived the pull. sha256 matched before each local copy was removed. The host `.env` had the same content as the workstation `.env.backup`. No contents were printed.

## T2: Results

- Repo edits were made as the plan specified. The Renovate object was removed whole. In pg-migrate, `do_postiz()`, the `run_all` call, the case arm and the usage word were removed, and a one-line removal comment was added. STANDARDS item 15 was struck through and the `analytics` example swapped in. BACKLOG has the table cell, the retirement sentence and the operator's quote. The service-classification plan has an appended `### 2026-11-22 — postiz DORMANT → DELETED` section.
- `bash -n scripts/pg-migrate.sh` passes, and RENOVATE_PARSES.
- The commit staged exactly 9 paths (4 deletions + 5 edits). Unrelated work (`07-UAT.md`, `.planning/trips/`, `projects/`) was not staged and not touched.
- Host: `git status --porcelain` was empty before the pull, so no patch was needed. `pull --ff-only` succeeded, HEAD = DEPLOY_SHA, and `stacks/selfhosted/postiz` is gone. The leftover untracked `.env` was moved to tank and the empty directory removed.
- Containers: 0 by compose label and 0 by name, before and after.
- Volumes: `postiz_postiz_{config,postgres,redis,uploads}`. Each device was checked and sits under `/mnt/fast/appdata/postiz/`. All four were removed by name, with no prune. 0 remain.
- Appdata: LXC_PRE 1,620 = LXC_POST 1,620, and `postgres/` is still present.
- Images: **none existed** (`NO_IMAGES` before removal). 0 after. No `docker rmi` was needed.
- Traefik router: **could not look via API**. `docker exec traefik wget .../api/http/routers` returned HTTP 404, so the API is not served there. Fallback: `grep -rIl -e postiz -e social.deercrest.info /mnt/fast/appdata/traefik` over yml/yaml/toml returned no files (grep rc=1 = no match). The labels of every container on LXC 100 also show 0 hits. With no container left, a Docker-provider router cannot exist.
- Cloudflare (report only, token host-side): `success=True count=1`, `CNAME deercrest.info proxied=True`. **The record exists.** It was not changed.
- T2 verify: `T2_OK`, ssh_rc=0, `INFRA_CLEAN`. The grep step was run with `/usr/bin/grep`, because workstation ugrep drops the `./` prefix that the plan's filters key on. It also adds `--exclude-dir=.claude` (a gitignored stale agent worktree, `.claude/worktrees/agent-a391a8c6fd47e3e2e`, which holds an old full checkout) and excludes all of `^./infra/` (gitignored local `terraform.tfstate*` files reference the mount, and the must_have excludes infra/). A tracked-files `git grep` with the plan's exact exclusions is also empty.
- Health check: exit 1. The only failure is the known, unrelated CONF-04 music-consumers assertion (Lady Gaga ARTPOP artist entities). Nothing new failed.
- Terraform was never run. No `.tf` file was edited.

### Final grep remainder (`git grep -niI postiz -- . ':!.planning'`), all intentional

```
BACKLOG.md:13         ~~postiz~~ (retired 2026-11-22 → Zernio)
BACKLOG.md:168        Postiz ... was retired 2026-11-22 — ... (#1582, Zernio, archive path)
RENOVATE-REVIEW.md:22 dated log, left as is
RENOVATE-REVIEW.md:24 dated log, left as is
STANDARDS.md:89       15. ~~postiz/compose.yaml~~ - stack retired 2026-11-22 ...
infra/lxc-selfhost.tf:273-274  Terraform bind mount, out of scope
scripts/pg-migrate.sh:248  postiz removal comment (removed 2026-11-22)
scripts/pg-migrate.sh:258  existing social-postiz removal comment
```

## Deviations from Plan

1. **[Rule 3 - Blocking] Gitignored workstation `.env` / `.env.backup` in `stacks/selfhosted/postiz/`.** After `git rm`, the directory still existed locally, and the verify needs `test ! -e`. Both files were copied to tank, sha256-verified, then removed locally. This is the same handling the plan prescribed for the host `.env`.
2. **[Rule 1 - Bug in verify] grep flavour and scope.** The plan's verify grep does not work with ugrep's output format, and it would hit gitignored tfstate files and a stale `.claude/` worktree. It was run with `/usr/bin/grep` and those exclusions, and cross-checked with `git grep`. This is described above.
3. My first exploratory grep, on the workstation, printed lines of the gitignored local `.env` into the agent transcript, including the Postgres connection string. Nothing was committed or sent anywhere. The stack is retired and its DB is not running, but the operator may want to treat that DB password as exposed (it is moot once the appdata is destroyed).

## Operator follow-ups (not done)

a. **Terraform mount.** Remove the `mount_point` for `/mnt/fast/appdata/postiz` (`infra/lxc-selfhost.tf` ~273-274) and destroy the `fast/appdata/postiz` dataset. This needs explicit approval. Landmine: LXC 100 has `ignore_changes`, so editing the `.tf` alone plans clean and does nothing. Removing the mount takes a deliberate `pct set` plus the `.tf` edit, with the plan read for `1 to destroy` (CLAUDE.md Infrastructure Warnings).
b. **Cloudflare.** Delete the `social.deercrest.info` record (it exists: CNAME → deercrest.info, proxied).
c. **Workstation.** Delete `~/.claude/skills/postiz/` and `~/.claude/secrets/postiz.env`, and remove the Postiz skill line from `~/.claude/CLAUDE.md`'s topic list.
d. **Retention.** Decide how long to keep the tarball, `postiz-workstation-env-20261122/` and the snapshot `fast/appdata/postiz@retire-postiz-20261122`. Destroying the dataset in (a) also destroys the snapshot, so the tarball is the copy that outlives it.
e. **Optional.** The stale agent worktree `.claude/worktrees/agent-a391a8c6fd47e3e2e` (branch `worktree-agent-a391a8c6fd47e3e2e`) is still registered in this checkout.

## Self-Check: PASSED

- Archive present on tank with sha256 recorded, and the snapshot is present (both verified over ssh).
- Commit `12f39e46` is on origin/main and is the host's HEAD.
