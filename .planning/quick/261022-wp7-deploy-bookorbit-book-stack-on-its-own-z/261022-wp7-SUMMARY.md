---
phase: quick/261022-wp7
plan: 01
subsystem: books
tags: [bookorbit, bookshelf, readarr, zfs, terraform, audiobookshelf]
status: incomplete — remaining: Breege BookOrbit + ABS accounts (pending operator); Bookshelf authors (blocked on hardcover.bookinfo.pro 429)
requires: [261022-cg6 dataset recipe]
provides: [BookOrbit at books.deercrest.info, fast/appdata/bookorbit{,/postgres}, Bookshelf hardcover pin]
key-files:
  created: [stacks/selfhosted/bookorbit/compose.yaml, stacks/selfhosted/bookorbit/bookorbit.yaml, stacks/selfhosted/bookorbit/.env.sample, stacks/selfhosted/bookorbit/README.md, stacks/selfhosted/wrappers/bookorbit.app.yaml]
  modified: [stacks/selfhosted/arrs/readarr.yaml, renovate.json5, infra/lxc-selfhost.tf, README.md, scripts/pg-migrate.sh, BACKLOG.md, RENOVATE-REVIEW.md]
  deleted: [stacks/selfhosted/books/compose.yaml, stacks/selfhosted/books/booklore.yaml, stacks/selfhosted/books/.env.sample, stacks/selfhosted/wrappers/books.app.yaml]
decisions:
  - "Whole books.deercrest.info host on BookOrbit's own auth (chain-no-auth), justified in the router comment and README"
  - "Fresh Bookshelf config carries only config.xml, so the API key is unchanged for readarr-exporter and Prowlarr"
  - "Breege's BookOrbit permissions planned as library_download, koreader_sync, kobo_sync, opds_access, notification_access (not applied)"
completed: 2026-10-23 (partial)
---

# Quick 261022-wp7: BookOrbit on its own ZFS datasets, Booklore retired, Bookshelf on hardcover — Summary

BookOrbit 3.5.0 serves https://books.deercrest.info under its own login, on `fast/appdata/bookorbit`
(mp37) and `.../postgres` (mp38, 16K). Both datasets are reconciled into Terraform and fully sent
to the backup pool. The library is read-only and scanned. Booklore is gone, and
`/mnt/tank/media/Books` is all `568:568` with the 7 Rowling ebooks and Windows Azure Pack 2013
hand-copied in.

Bookshelf runs the pinned hardcover flavour on a fresh DB, but **0 authors were added**: its hosted
metadata service is down.

**Stopped early:** creating Breege's BookOrbit account was denied by the permission system
(`[Permission Grant]`). Following the brief, I stopped there. The ABS `breege` user, the docs
commit (T5 step 7) and the snapshot-register row were not done.

## Per task

| Task | Result | Commit |
|---|---|---|
| 1 Preflight, stack, Booklore retirement, Renovate | done | 1ecb3108, 04a57b6d |
| 2 Host steps on atlantis (executed over ssh under the operator's authorisation) | done, HOTPLUG | — (host only) |
| 3 Terraform reconcile, deploy, admin setup, DNS | done (DNS was already present) | 3caeadee |
| 4 Bookshelf to hardcover | switch, clients and Prowlarr done; **authors blocked** | f83685ec |
| 5 Library, accounts, matrix, docs | library, ABS after, matrix and estate checks done; **stopped at Breege** | none (uncommitted evidence) |

All evidence is keyed in `261022-wp7-PREFLIGHT.txt` (T2-RESULT-*, T3-*, T4-*, BO-SCAN, ABS-AFTER,
EDGE-MATRIX, T5-*).

## Deviations

1. **[Rule 3] Task 2 was run by the executor**, per the orchestrator's relay of the operator's
   authorisation. Blocks A–E ran exactly as written. The only change was that the Block D probe
   image `postgres:18-trixie` was confirmed present before it was used.
2. **DNS was already present.** A proxied CNAME `books -> deercrest.info` pre-existed from Booklore
   days, so "setup before DNS" became "setup before anyone holds the 64-hex token". Setup returned
   201, then 409, about 3 minutes after `up`.
3. **[Rule 1] Push race (self-inflicted, recovered).** The T4 push was rejected because Renovate
   #536 had merged first. The scripted host step still pulled origin, which had no pin, and started
   readarr for about 1 minute as `:softcover` on the empty fresh config dir. That instance had no
   clients, indexers or authors, so nothing could be grabbed. I stopped it, removed only the files
   it had created (keeping `config.xml`), rebased, pushed f83685ec, pulled and started the hardcover
   image. The preserved `config.softcover-pre-261022` was never touched.
4. **The `config.xml` mode is 0660, not 0644.** It holds the ApiKey; the original was 0770.
5. **Plan defect in the T3 verify.** `sed -n '/ignore_changes = \[/,/\]/p'` stops at the `]` in
   `user_account[0]`, so it never reaches `mount_point,`. I confirmed with awk that `mount_point,`
   is present in `ignore_changes`.
6. **The edge matrix's register/setup POST with `{}` returns 400, not 403.** DTO validation runs
   before the closed-registration check. `GET /api/v1/auth/setup-status` reads
   `allowRegistration:false, needsSetup:false`. I did not send a valid-shaped register body, which
   would have meant inventing an address.
7. **The renovate validator was not run locally.** The local npx cache has renovate 37.x, which
   rejects `managerFilePatterns` at HEAD too. CI compose-validate passed for 3caeadee. Check the run
   for f83685ec.
8. **No forced Readarr rescan.** Adding the root folder auto-started `RescanFolders`; it was still
   running against the dead metadata service when I stopped.

## Blocked / remaining

- **Breege in BookOrbit.** `POST /api/v1/users` (with `permissionNames`) was denied as
  `[Permission Grant]`. Nothing ran, and `bookorbit.env` holds only the admin entries. Upstream
  v3.5.0 flow: create the user (it returns a `resetUrl` with a token), then
  `POST /api/v1/auth/reset-password {token,newPassword}`. Alternatively, set her password in the
  UI under Admin → Users.
- **Breege in ABS.** Not attempted, because it is the same class of action. ABS users are still
  `[damian]`.
- **Bookshelf authors (R10).** 0 of 10 were added. `hardcover.bookinfo.pro` answers 429 and then
  times out (upstream #179/#180). Retry when it answers 200, or self-host rreading-glasses with a
  Hardcover API key (a new service, so it needs an operator decision).
- **T5 docs: done in a follow-up round, 2026-10-23.** README Current Stacks, DEPLOYMENT.md § 3,
  MEDIA.md § 3 and the `.planning/SNAPSHOT-REGISTER.md` row for `tank/media/Books@pre-wp7-20261022`
  are committed with PREFLIGHT.txt and this SUMMARY.

**Status: incomplete.** Remaining:
- the Breege BookOrbit and ABS accounts, pending an operator decision;
- the Bookshelf authors, blocked on `hardcover.bookinfo.pro` returning 429.

## Follow-ups (from the plan)

- MAM task: Bookshelf has native MyAnonaMouse support. Once indexers are ready, switch authors
  from `monitor: none` to `existing`.
- Book Dock plus an rw BookOrbit mount; enabling OPDS; optional Authelia OIDC.
- The flat `J.K. Rowling/` layout (it also has a nested `J.K. Rowling/J.K. Rowling/` folder); the
  stray LEGO BOOST root folder; `wap2013.pdf` (not imported); qBit category `readarr` (empty).
- Owner-map revert: read `/root/bookorbit/books-owner-pre.tsv0` on atlantis NUL-delimited and
  `chown -h` each path back to its recorded `%U:%G`, or roll back to
  `tank/media/Books@pre-wp7-20261022`.

## Self-Check

Commits 1ecb3108, 04a57b6d, 3caeadee and f83685ec are on origin/main. `~/.claude/secrets/bookorbit.env`
is mode 600. Self-Check: PASSED for the completed scope; the plan is incomplete, as listed above.
