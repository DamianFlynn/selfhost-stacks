---
phase: quick-261122-fkq
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - stacks/selfhosted/postiz/compose.yaml
  - stacks/selfhosted/postiz/postiz.yaml
  - stacks/selfhosted/postiz/README.md
  - stacks/selfhosted/wrappers/postiz.app.yaml
  - renovate.json5
  - scripts/pg-migrate.sh
  - STANDARDS.md
  - BACKLOG.md
  - .planning/plans/service-classification.plan.md
autonomous: true
requirements: [QUICK-261122-fkq]

must_haves:
  truths:
    - "A verified tarball of /mnt/fast/appdata/postiz exists on tank, off LXC 100's root disk, with its sha256 and size recorded"
    - "If /mnt/fast/appdata/postiz is its own ZFS dataset, it carries the snapshot @retire-postiz-20261122"
    - "The postiz stack definition, its wrapper, its Renovate label rule and its pg-migrate target are gone from origin/main and from the host checkout"
    - "Repo-wide grep for postiz (outside .git, .planning, RENOVATE-REVIEW.md and infra/) returns only dated retirement notes"
    - "LXC 100 has no postiz docker volumes, no postiz-app image and no postiz Traefik router, and the appdata files are still present"
    - "Terraform files are byte-identical to HEAD before the task; terraform was never run"
    - "Cloudflare's social.deercrest.info record state is reported, not changed"
  artifacts:
    - path: "/mnt/tank/backups/retired-stacks/postiz-appdata-20261122.tar.gz (atlantis)"
      provides: "Archive of Postiz appdata, taken before any deletion"
    - path: "BACKLOG.md"
      provides: "Retirement record with date, reason (LinkedIn personal profile, gitroomhq/postiz-app#1582) and Zernio replacement"
      contains: "retired 2026-11-22"
    - path: ".planning/plans/service-classification.plan.md"
      provides: "Dated note: postiz DORMANT -> DELETED"
      contains: "DELETED"
  key_links:
    - from: "T1 archive evidence (sha256, entry count)"
      to: "T2 deletion steps"
      via: "T2 step 0 refuses to start unless the archive file exists and gzip -t passes"
      pattern: "postiz-appdata-20261122.tar.gz"
    - from: "local commit"
      to: "host checkout /mnt/fast/stacks"
      via: "push gate, then git pull --ff-only on LXC 100"
      pattern: "rev-parse HEAD"
---

<objective>
Retire Postiz from the Deer Crest estate: archive its data first, then delete the stack definition and
every live repo reference, deploy the deletion to LXC 100, and remove the leftover Docker residue.

Purpose: the operator decided on 2026-11-22: *"I prefer self-hosted every time, but if it will not
work, it's dead."* Self-hosted Postiz cannot connect a personal LinkedIn profile (upstream
gitroomhq/postiz-app#1582, still OPEN on 2026-11-22; its latest comment says adding accounts on a
self-hosted instance is fundamentally broken), and LinkedIn is the primary platform. Social posting,
scheduling and analytics move to Zernio (SaaS, already connected to LinkedIn and YouTube; X still to
be added). Prior research: `neocortex/clients/deer-crest/postiz-vs-zernio-comparison/index.md`
(2026-07-06). Postiz has been DORMANT (`profiles: ["dormant"]`) since 2026-09-25; no containers exist.

Output: one archive on tank (T1, host-only), one commit removing Postiz from the repo, deployed to the
host, with Docker residue removed and assertions recorded (T2).

OUT OF SCOPE, hard: Terraform. Do not edit `infra/*.tf`, do not run `terraform` in any form. The bind
mount `/mnt/fast/appdata/postiz` (`infra/lxc-selfhost.tf` lines 273-274) and the host path/dataset
behind it stay. Do not delete any appdata contents. Do not delete the Cloudflare record. The
workstation's `~/.claude/skills/postiz/` and `~/.claude/secrets/postiz.env` are outside the repo and
are not touched; they are operator follow-ups.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@./CLAUDE.md
@./CONVENTIONS.md
@.planning/quick/261122-e3e-deploy-rybbit-web-analytics-as-analytics/261122-e3e-SUMMARY.md

Facts gathered at planning time (2026-11-22, re-check anything you lean on; line numbers go stale):

- Live repo hits for `postiz` outside `.git` and `.planning`:
  - `stacks/selfhosted/postiz/{compose.yaml,postiz.yaml,README.md}`: delete the whole directory.
  - `stacks/selfhosted/wrappers/postiz.app.yaml`: delete.
  - `renovate.json5` around line 379-386: one `packageRules` object, description
    `"Auto-label by stack: Postiz (Social Media Manager)"`, `matchFileNames`
    `**/stacks/selfhosted/postiz/**`, `addLabels` `stack:postiz`. Delete the whole object, including
    its trailing comma, so the neighbouring Teleport and ARRs objects stay well-formed.
  - `scripts/pg-migrate.sh`: function `do_postiz()` (around 248-255), the `do_postiz` call in
    `run_all()`, the `postiz)        do_postiz ;;` case arm, and the word `postiz` in the usage line
    `echo "       keeper open-archiver postiz calcom teleport"`. A removal comment already exists
    for social: `# The social-postiz and rybbit migration targets were removed 2026-11-22 ...`.
  - `STANDARDS.md` line ~89: `15. ✅ **postiz/compose.yaml** - Already had proper header (newly created)`.
    Line ~137: `  - Examples: \`postiz\`, \`teleport\`, \`dawarich\`, \`pwpush\`, etc.`
  - `BACKLOG.md` line ~13: table cell `**postiz** (own stack, dormant)` in the `analytics` column.
    Line ~168: `- **analytics**: Rybbit (web analytics). Postiz (social media scheduling) lives in its own \`postiz/\` stack`.
  - `RENOVATE-REVIEW.md` lines 22, 24: a dated log. LEAVE IT.
  - `infra/lxc-selfhost.tf` lines 273-274: Terraform. LEAVE IT (read-only).
- `scripts/deploy-stacks.sh` has no postiz reference (checked); nothing to change there.
- `.planning/plans/service-classification.plan.md` lists `postiz` (3) under **DORMANT** (line ~146)
  and notes `postiz/` survived the social de-duplication (lines ~190-193). It ends with an
  `### Still open` section.
- Host model: workstation commit -> push (gate on success) -> LXC 100 `root@172.16.1.159`
  `/mnt/fast/stacks` -> `git status --porcelain` (if dirty, save a patch first) -> `git pull --ff-only`.
- Atlantis `root@172.16.1.158` is real root on the Proxmox host. Existing archive convention on tank:
  `/mnt/tank/backups/<thing>` (e.g. `/mnt/tank/backups/teslamate-db`, `/mnt/tank/backups/immich-db`,
  `/mnt/tank/backups/hufflepuff-scavenge`). This plan uses `/mnt/tank/backups/retired-stacks/`.
- Cloudflare recipe (from 261122-e3e): on LXC 100 only,
  `TOK=$(tr -d '\r\n' < /mnt/fast/appdata/traefik/secrets/cf_dns_api_token)`, zone id
  `a17921aa68381169889f3d621fd9ede6`, header passed via `-H @<(printf 'Authorization: Bearer %s\n' "$TOK")`
  (CONVENTIONS § 7: credentials never enter argv). Never print the token.
- Workstation `grep` is ugrep (memory note). The commands below use flags ugrep and GNU grep share;
  if a count looks wrong, re-run with `/usr/bin/grep`.
- Remote commands: bound them Linux-side with `timeout` inside the remote string, use
  `set -o pipefail`, and read the ssh exit code (CONVENTIONS §§ 1-3). macOS has no GNU `timeout`.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Archive Postiz appdata on atlantis before anything is deleted (host-only, no commit)</name>
  <files>(host-only, atlantis) /mnt/tank/backups/retired-stacks/postiz-appdata-20261122.tar.gz; ZFS snapshot &lt;dataset&gt;@retire-postiz-20261122 if the path is its own dataset. No repo files.</files>
  <action>
Per locked decision 1. Everything runs on atlantis via `ssh root@172.16.1.158` with the remote
string wrapped in `bash -c 'set -euo pipefail; ...'` and every command bounded by `timeout 120`.
Read and record each ssh exit code; a non-zero exit is "could not look", never "nothing there".

1. Terraform fence (record, do not change): on the workstation run
   `git diff --quiet HEAD -- infra/ && echo INFRA_CLEAN` and `git hash-object infra/lxc-selfhost.tf`.
   Record both. Expect `INFRA_CLEAN`. Do not open any `.tf` file for editing.

2. Identify what backs the path. On atlantis:
   `findmnt -no SOURCE,FSTYPE,TARGET --target /mnt/fast/appdata/postiz` and
   `zfs list -H -o name,mountpoint,used,refer | awk '$2=="/mnt/fast/appdata/postiz"'`.
   Also `du -sh /mnt/fast/appdata/postiz/*` and `find /mnt/fast/appdata/postiz | wc -l` (record as
   PRE_COUNT; expect a postgres dir of ~15M and near-empty config/redis/uploads).
   - If the zfs line is non-empty (the path is its own dataset, e.g. `fast/appdata/postiz`):
     `zfs snapshot <ds>@retire-postiz-20261122`, then assert
     `zfs list -H -t snapshot -o name <ds>@retire-postiz-20261122` prints exactly that name.
   - If it is empty (the path sits inside a parent dataset such as `fast/appdata`): take NO
     snapshot of the parent (that would pin every other app's data) and record
     "not its own dataset: backed by <SOURCE>; no snapshot taken, tarball only".

3. Choose the archive location. `test -d /mnt/tank/backups` must succeed (it is the existing tank
   convention). Confirm it is on tank and not on fast or LXC root:
   `findmnt -no SOURCE --target /mnt/tank/backups` must start with `tank`. Then
   `mkdir -p /mnt/tank/backups/retired-stacks`. If that mkdir or the tar below fails on tank (the
   `aclmode=restricted` ACL trap in CLAUDE.md affects chmod, not plain file creation, so it should
   not, but if it does), fall back to `/mnt/fast/appdata-retired/` beside, not inside,
   `/mnt/fast/appdata` on atlantis, and say so explicitly in the SUMMARY with the reason. Never write the
   archive under `/mnt/fast/appdata/postiz` itself and never on LXC 100's root disk.

4. Write the tarball. Real root on atlantis reads the idmapped (100000+) owners without trouble:
   `tar -C /mnt/fast/appdata -czf /mnt/tank/backups/retired-stacks/postiz-appdata-20261122.tar.gz postiz`.
   Then `chmod 600` on it (if chmod fails `EPERM` because of the tank ACL, record that; the file is
   still root-owned). The postgres data may hold OAuth tokens for social accounts, which is why the
   mode matters.

5. Verify and record (all must hold):
   - `gzip -t <archive> && echo GZIP_OK` prints `GZIP_OK`.
   - `tar -tzf <archive> | wc -l` is > 0 and equals PRE_COUNT (tar lists the same dirs and files as
     `find postiz`; if they differ by a small number, record both and the difference, e.g. sockets that tar
     skips. Do not paper over it).
   - `tar -tzf <archive> | grep -c '^postiz/postgres/'` is > 0 (the one component with real data).
   - `sha256sum <archive>` and `stat -c '%s' <archive>`: record both in the SUMMARY.
   - `find /mnt/fast/appdata/postiz | wc -l` still equals PRE_COUNT (nothing was deleted).

Do not commit anything in this task. Do not touch Docker in this task.
  </action>
  <verify>
    <automated>ssh -o ConnectTimeout=10 root@172.16.1.158 "timeout 120 bash -c 'set -euo pipefail; A=/mnt/tank/backups/retired-stacks/postiz-appdata-20261122.tar.gz; test -s \$A; gzip -t \$A; n=\$(tar -tzf \$A | wc -l); test \$n -gt 0; p=\$(tar -tzf \$A | grep -c ^postiz/postgres/); test \$p -gt 0; sha256sum \$A; stat -c %s \$A; echo ENTRIES=\$n PG=\$p; test -d /mnt/fast/appdata/postiz/postgres; echo T1_OK'"; echo "ssh_rc=$?"</automated>
  </verify>
  <done>The archive exists on tank (or on the documented fallback), `gzip -t` passes, its entry count is > 0 and matches the live tree's count (or the difference is explained), it contains `postiz/postgres/` entries, and its sha256 and byte size are recorded. The snapshot exists if and only if the path is its own dataset, with the decision recorded either way. The appdata tree is unchanged, `infra/` is untouched (`INFRA_CLEAN`), and the T1 verify prints `T1_OK` with `ssh_rc=0`.</done>
</task>

<task type="auto">
  <name>Task 2: Remove Postiz from the repo, deploy the deletion, clear Docker residue on LXC 100, assert</name>
  <files>stacks/selfhosted/postiz/ (delete: compose.yaml, postiz.yaml, README.md), stacks/selfhosted/wrappers/postiz.app.yaml (delete), renovate.json5, scripts/pg-migrate.sh, STANDARDS.md, BACKLOG.md, .planning/plans/service-classification.plan.md; host-side: /mnt/fast/stacks checkout and Docker volumes/images on LXC 100</files>
  <action>
Per locked decisions 2 and 3. Approach copied from 261122-e3e's retirement of `social`.

0. Gate: re-run the T1 verify command. If it does not print `T1_OK` with `ssh_rc=0`, STOP; nothing
   gets deleted without the archive.

1. Repo edits (decision 2), in the main checkout on `main`:
   - `git rm -r stacks/selfhosted/postiz` and `git rm stacks/selfhosted/wrappers/postiz.app.yaml`.
   - `renovate.json5`: delete the whole Postiz label `packageRules` object (description through its
     closing brace and trailing comma). Leave every other rule alone.
   - `scripts/pg-migrate.sh`: delete `do_postiz()` entirely, the `do_postiz` line in `run_all()`, and
     the `postiz)` case arm. Change the usage line to `echo "       keeper open-archiver calcom teleport"`.
     Where `do_postiz()` was, leave a one-line comment in the style of the existing social one:
     `# The postiz migration target was removed 2026-11-22 with the postiz stack (retired: no personal-LinkedIn support self-hosted).`
     That line must contain the literal `removed 2026-11-22` (the final grep allowlist keys on it) and
     must not contain `do_postiz` (the verify greps for that token).
   - `STANDARDS.md`: keep item 15 so the numbering stays intact, and reword it to
     `15. ~~postiz/compose.yaml~~ - stack retired 2026-11-22 and removed from the repo`. In the
     internal-networks examples, replace `` `postiz` `` with `` `analytics` `` (an existing
     per-stack bridge network, `stacks/selfhosted/analytics/compose.yaml`).
   - `BACKLOG.md`: in the line ~13 table cell, replace `**postiz** (own stack, dormant)` with
     `~~postiz~~ (retired 2026-11-22 → Zernio)`. Replace the line ~168 sentence after
     `Rybbit (web analytics).` with:
     `Postiz (social media scheduling) was retired 2026-11-22 — self-hosted Postiz cannot connect a personal LinkedIn profile (upstream gitroomhq/postiz-app#1582, open), and LinkedIn is the primary platform. Posting, scheduling and social analytics moved to Zernio (SaaS). Research: neocortex/clients/deer-crest/postiz-vs-zernio-comparison/index.md (2026-07-06). Appdata archived to atlantis /mnt/tank/backups/retired-stacks/postiz-appdata-20261122.tar.gz.`
     Keep the operator's words as the record of the decision: add, on its own line directly below,
     `  Operator, 2026-11-22: "I prefer self-hosted every time, but if it will not work, it's dead."`
     (If T1 used the fallback location, put that path instead.)
   - `.planning/plans/service-classification.plan.md`: append at the end a dated section
     `### 2026-11-22 — postiz DORMANT → DELETED` with 3-5 lines: reason (as above, #1582, Zernio),
     what was removed (stack dir, wrapper, Renovate rule, pg-migrate target), archive path, sha256
     and snapshot status from T1, and that the Terraform bind mount `/mnt/fast/appdata/postiz` and its
     backing path remain pending operator approval. Do not edit the historic DORMANT table row; it is
     a dated record.

2. Local checks, then the repo-wide grep assertion (decision 2):
   `bash -n scripts/pg-migrate.sh`; parse renovate.json5 as a JS object literal (JSON5 is a subset):
   `node -e "new Function('return ' + require('fs').readFileSync('renovate.json5','utf8'))()" && echo RENOVATE_PARSES`;
   then
   `grep -rniI postiz --exclude-dir=.git --exclude-dir=.planning . | grep -v -e '^./RENOVATE-REVIEW.md:' -e '^./infra/lxc-selfhost.tf:' | grep -v -e 'retired 2026-11-22' -e 'removed 2026-11-22'`
   must print nothing. Then list what remains, without the last filter, and paste it into the SUMMARY
   as the intentional set. Expected: RENOVATE-REVIEW.md ×2, infra/lxc-selfhost.tf ×2, pg-migrate.sh
   (the two removal comments), STANDARDS.md item 15, BACKLOG.md ×2. Any other hit gets fixed or justified.
   Re-assert the Terraform fence: `git diff --quiet HEAD -- infra/ && echo INFRA_CLEAN`.

3. Commit by explicit path only. The tree has unrelated uncommitted work (`07-UAT.md`,
   `.planning/trips/`, `projects/`) that must not be staged, stashed or reset away. The `git rm`
   paths are already staged; add `renovate.json5 scripts/pg-migrate.sh STANDARDS.md BACKLOG.md
   .planning/plans/service-classification.plan.md` by name. Check that
   `git diff --cached --name-only` lists exactly the 4 deleted files plus those 5. Message:
   `chore(postiz): retire postiz — archive appdata, delete stack, renovate rule and pg-migrate target`
   with a body naming #1582, Zernio and the archive path.

4. Push gate: `git push origin main`. If it is rejected (Renovate races main), do NOT stash and do
   NOT `pull --rebase` with the dirty tree. Use the 261122-e3e recipe: `git fetch origin`, check that
   no incoming commit touches the 9 paths (`git diff --name-only HEAD origin/main`), then
   `git reset --keep origin/main` and `git cherry-pick <sha>`, and push again. Proceed only when
   `git rev-parse HEAD` == `git rev-parse origin/main`. Record DEPLOY_SHA.

5. Host pull, on LXC 100 `ssh root@172.16.1.159`, bounded with `timeout`:
   `git -C /mnt/fast/stacks status --porcelain`. If it is non-empty, first save
   `git -C /mnt/fast/stacks diff > /mnt/fast/stacks-host-patch-20261122-fkq.patch` and record the
   paths. Do not pull over host edits to the paths this commit touches; stop and report instead.
   Then `git -C /mnt/fast/stacks pull --ff-only` and assert the host `rev-parse HEAD` == DEPLOY_SHA and
   `test ! -e /mnt/fast/stacks/stacks/selfhosted/postiz`. If a host-only untracked
   `stacks/selfhosted/postiz/.env` survives the pull (git leaves untracked files), move it into the
   archive dir on tank via atlantis (do not print its contents), then remove the leftover directory.

6. Docker residue (decision 3), on LXC 100:
   - Pre-check: `docker ps -a --filter label=com.docker.compose.project=postiz -q | wc -l` and
     `docker ps -a --format '{{.Names}}' | grep -ci postiz` must both be 0. If not, STOP (the plan
     assumed no containers).
   - Record `find /mnt/fast/appdata/postiz | wc -l` as LXC_PRE.
   - `docker volume ls -q | grep '^postiz_'`. Expect exactly `postiz_postiz_config`,
     `postiz_postiz_postgres`, `postiz_postiz_redis`, `postiz_postiz_uploads`. For each one,
     `docker volume inspect -f '{{.Options.device}}'` must be under `/mnt/fast/appdata/postiz/`
     (a bind volume, so removing it leaves the host files in place). Then `docker volume rm` those
     four by name. Do not use `docker volume prune`.
   - `find /mnt/fast/appdata/postiz | wc -l` must still equal LXC_PRE, and
     `test -d /mnt/fast/appdata/postiz/postgres` must succeed.
   - Images: `docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep -i postiz`. Remove only
     images whose repository contains `postiz` (e.g. `ghcr.io/gitroomhq/postiz-app`) with
     `docker rmi <repo:tag>`. Do NOT remove the shared postgres/redis images, which other stacks use.
     Re-run the listing and expect 0 lines.
   - Traefik router: `docker exec traefik wget -qO- http://localhost:8080/api/http/routers` (`:8080`
     is container-internal only) piped to `grep -ci -e postiz -e social.deercrest.info`; expect 0.
     If the API call fails, record "could not look via API" and
     instead `grep -rIl -e postiz -e social.deercrest.info /mnt/fast/appdata/traefik --include='*.yml' --include='*.yaml' --include='*.toml'`
     must print nothing. Fail closed: a failed probe is not a pass.
   - Cloudflare (REPORT ONLY): on LXC 100, with the token read host-side as in the context,
     GET `https://api.cloudflare.com/client/v4/zones/a17921aa68381169889f3d621fd9ede6/dns_records?name=social.deercrest.info`,
     and print only `success`, the record count, and for each record `type`, `content` and `proxied`
     (parse with `python3 -I -c` or `jq` on the host). Do not print the token or send a DELETE.
     `success:false` or a curl failure is "could not look"; record it as that.

7. Health: run `bash scripts/quick-health-check.sh` from the workstation and record the exit code and
   any failures. The CONF-04 music-consumers failure is known from earlier and unrelated; any NEW
   failure must be investigated before declaring done.

SUMMARY must include: DEPLOY_SHA; the T1 archive path, sha256, size, entry count and snapshot
decision; the final grep remainder list; volume/image/router/Cloudflare results; and these operator
follow-ups (not done by the executor):
(a) remove the Terraform `mount_point` for `/mnt/fast/appdata/postiz` (`infra/lxc-selfhost.tf`
~273-274) and destroy its backing dataset/path. This needs explicit operator approval, and note the
landmine: LXC 100 has `ignore_changes`, so a `.tf` edit plans clean and does nothing to the live
container; removing the mount means a deliberate `pct set` plus a `.tf` edit, with the plan read for
`1 to destroy` (CLAUDE.md Infrastructure Warnings);
(b) delete the Cloudflare `social.deercrest.info` record if one exists;
(c) on the workstation, delete `~/.claude/skills/postiz/` and `~/.claude/secrets/postiz.env`, and
remove the Postiz skill line from `~/.claude/CLAUDE.md`'s topic list;
(d) once the operator is satisfied, decide how long to keep the tarball and snapshot.
  </action>
  <verify>
    <automated>cd /Users/damian/Development/damianflynn/selfhost-stacks && test ! -e stacks/selfhosted/postiz && test ! -e stacks/selfhosted/wrappers/postiz.app.yaml && bash -n scripts/pg-migrate.sh && ! grep -n 'do_postiz' scripts/pg-migrate.sh && ! grep -n 'stack:postiz' renovate.json5 && node -e "new Function('return ' + require('fs').readFileSync('renovate.json5','utf8'))()" && test -z "$(grep -rniI postiz --exclude-dir=.git --exclude-dir=.planning . | grep -v -e '^./RENOVATE-REVIEW.md:' -e '^./infra/lxc-selfhost.tf:' | grep -v -e 'retired 2026-11-22' -e 'removed 2026-11-22')" && git diff --quiet HEAD -- infra/ && test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" && ssh -o ConnectTimeout=10 root@172.16.1.159 "timeout 120 bash -c 'set -euo pipefail; test \$(git -C /mnt/fast/stacks rev-parse HEAD) = $(git rev-parse HEAD); test ! -e /mnt/fast/stacks/stacks/selfhosted/postiz; test \$(docker volume ls -q | grep -c ^postiz_ || true) -eq 0; test \$(docker images --format {{.Repository}} | grep -ci postiz || true) -eq 0; test \$(docker ps -a --format {{.Names}} | grep -ci postiz || true) -eq 0; test -d /mnt/fast/appdata/postiz/postgres; echo T2_OK'"; echo "ssh_rc=$?"</automated>
  </verify>
  <done>origin/main and the host checkout are both at DEPLOY_SHA, and neither contains the postiz stack or wrapper. pg-migrate.sh parses with no `do_postiz`, and renovate.json5 parses with no `stack:postiz`. The repo grep remainder is only the dated retirement notes, RENOVATE-REVIEW.md and infra/, and is listed in the SUMMARY. `infra/` has no diff and terraform was never run. LXC 100 has 0 postiz volumes, images and containers, the Traefik router check is 0 (or the file-grep fallback is clean), and the appdata tree count is unchanged. The Cloudflare record state is reported. The verify prints `T2_OK` with `ssh_rc=0`, and the health check shows no new failure.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Workstation ↔ LXC 100 / atlantis (ssh) | Root shells on the Docker host and the hypervisor; destructive commands cross here |
| Public git repo | Everything committed is world-readable |
| LXC 100 → Cloudflare API | The DNS token lives host-side only |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-fkq-01 | Tampering / DoS | `terraform apply` in infra/ (can destroy LXC 100) | mitigate | Terraform is out of scope. No `.tf` edits and no terraform runs; `git diff --quiet HEAD -- infra/` is asserted in T1 and T2 |
| T-fkq-02 | Tampering (data loss) | Postiz appdata | mitigate | T1 archives (and snapshots, if it is its own dataset) before any deletion. T2 step 0 refuses to run without `T1_OK`. Only named bind volumes are removed (no `prune`), each one's device is checked first, and the file count is compared before and after |
| T-fkq-03 | Information disclosure | Archive contains postgres data (possible social OAuth tokens) | mitigate | Archive goes on tank under root, `chmod 600`, and is never copied to the workstation or the repo; any host `.env` is moved, not printed |
| T-fkq-04 | Information disclosure | Cloudflare token | mitigate | Read and used on LXC 100 only via `-H @<(printf ...)` (CONVENTIONS § 7); only record type/content/proxied are printed |
| T-fkq-05 | Tampering | Unrelated uncommitted work in the checkout | mitigate | Stage by explicit path, check `git diff --cached --name-only`, never stash; on push rejection use `reset --keep` + cherry-pick |
| T-fkq-06 | Tampering | Shared postgres/redis images | mitigate | `docker rmi` only on repositories containing `postiz` |
| T-fkq-07 | Spoofing | Dangling `social.deercrest.info` DNS record | accept | Report only. With no router the origin returns Traefik's 404, and deletion is the operator's decision (follow-up b) |
</threat_model>

<verification>
- T1 verify prints `T1_OK`, ssh_rc=0; archive sha256/size/entry count recorded.
- T2 verify prints `T2_OK`, ssh_rc=0.
- `git diff --quiet HEAD -- infra/` holds at the end; no terraform command appears in the transcript.
- Final grep remainder listed in the SUMMARY and every line is intentional.
</verification>

<success_criteria>
Postiz exists only as a verified archive on tank (plus a snapshot if it has its own dataset), dated
retirement notes in BACKLOG.md, STANDARDS.md, pg-migrate.sh and the service-classification plan, the
untouched dated RENOVATE-REVIEW.md log, and the Terraform mount left for operator approval. No stack
definition, wrapper, Renovate rule, migration target, Docker volume, image or Traefik router remains.
</success_criteria>

<output>
Create `.planning/quick/261122-fkq-retire-postiz-archive-data-delete-stack-/261122-fkq-SUMMARY.md` when done
</output>
