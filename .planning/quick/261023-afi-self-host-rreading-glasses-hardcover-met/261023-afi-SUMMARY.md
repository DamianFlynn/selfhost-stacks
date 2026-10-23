---
phase: quick/261023-afi
plan: 01
status: complete
subsystem: arrs / books
tags: [rreading-glasses, bookshelf, readarr, hardcover, postgres18, renovate]
key-files:
  created:
    - stacks/selfhosted/arrs/rreading-glasses.yaml
    - stacks/selfhosted/arrs/.env.sample
  modified:
    - stacks/selfhosted/arrs/compose.yaml
    - renovate.json5
decisions:
  - "Pin form is `hardcover@sha256:` (tag + digest), not silo's digest-only form: a digest-only ref would be tracked by Renovate against `latest`, which is the Goodreads flavour"
  - "DB on a private `internal: true` network only rreading-glasses joins, not on t3_proxy with readarr"
  - "mem_limit 512m: Go limit = 90% of cgroup, LRU = 50% of that, ~230 MB hot cache over Postgres"
  - "postgres:18-alpine (estate majority form), bind dir root:root 0755"
metrics:
  completed: 2026-10-23
---

# Quick 261023-afi: self-hosted rreading-glasses for Bookshelf - Summary

Bookshelf's metadata server now runs in the arrs stack instead of on the overloaded hosted
`hardcover.bookinfo.pro`. The image is `blampe/rreading-glasses:hardcover@sha256:3f017a51...` and
its cache is `rreading-glasses-db` (postgres:18-alpine) on ZFS `fast/appdata/arrs`.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | 3cbf8f23 | feat(261023-afi): self-hosted rreading-glasses Hardcover metadata server for Bookshelf (CI compose-validate run 39912301520: success) |

## Evidence

- Host lint: `docker compose -f stacks/selfhosted/arrs/compose.yaml config -q` rc=0 with no
  warnings. `HARDCOVER_AUTH` is `${HARDCOVER_AUTH:-}`, so compose stays silent when it is unset.
- DB: healthy. `stat -f -c %t /var/lib/postgresql` gives 2fc12fc1, PGDATA is
  `/var/lib/postgresql/18/docker` and the server is PostgreSQL 18.4. There is one bind mount and
  no volume. The DB is on network `rreading-glasses` only (internal=true), with no ports and a
  512 MiB memory limit.
- App: up, GOMEMLIMIT 456340275 (~435 MiB), "listening on :8788". `/swagger.json` returns 200 and
  `/search?q=John%20Grisham` returns 200 (0.8 s). `/author/206165` returns 200 with name John
  Grisham. The token in the container is checked by shape only (Bearer, unquoted). Its value was
  never printed.
- Bookshelf `metadataSource`: changed from `https://hardcover.bookinfo.pro` to
  `http://rreading-glasses:8788`, confirmed by reading it back.
- check-music-freeze `DECLARED_INTERP_EXPECTED` stays 8 because only literal host paths were added.

## Deviations from Plan

**1. [Rule 1 - Bug] PG18 init failed on the nfsv4-ACL arrs dataset.** On first start the
entrypoint, running as root, created `18/` as 0770 root:root. It then dropped to uid 70, which
could not traverse that directory, and the container restart-looped on `mkdir ... 18/docker:
Permission denied`. The silo and bookorbit precedents are on posix-ACL datasets and never hit
this. Fix: `chmod 0755 .../postgres/18` on the host, after which the DB initialised cleanly. The
trap and the pre-create command are recorded in the yaml comment.

**2. [Rule 2] The DB is not on t3_proxy.** The brief put both services on readarr's network.
Postgres instead sits on a private internal network, so the ~100 containers on t3_proxy cannot
reach it.

**3. Pin form.** The pin is tag + digest rather than silo's digest-only form. Reason: see decisions.

**4. arrs/.env.sample did not exist.** It was created with every key name from the host `.env`
and placeholder values.

## Blocked (Task 2, steps 4-5)

The permission classifier denied two things. The first was the author lookup and add for "John
Grisham" and "Alexandra Potter" (monitor all, then AuthorSearch). The second was the
README.md/MEDIA.md notes. Neither author exists in Bookshelf yet. Only J.K. Rowling and Yevgeniy
Brikman exist, both monitor=none. Both steps need the operator's direct authorisation.

## Self-Check: PASSED
- rreading-glasses.yaml, .env.sample present; commit 3cbf8f23 on origin/main and on the host.

## Completion (orchestrator, 2026-10-23)

Task 2 steps blocked for the executor were run by the orchestrator on the operator's direct request
("Add Grisham to the search and alexandra potter"):
- John Grisham (Bookshelf author 3, Hardcover 206165) and Alexandra Potter (author 4, Hardcover
  147531) added: root `/media/Books`, quality profile **Spoken** (2) — Grisham's on-disk collection is
  audio and the operator prefers audiobooks — metadata profile Standard, monitor all + new.
- Each shows 1 book so far (fresh rreading-glasses fills large authors in the background).
- AuthorSearch: Grisham → grabbed `John.Grisham-The.Firm.Scott.Brick-PoF` (NZBgeek → SABnzbd
  `audiobooks`); Potter → 0 reports. Only 1 indexer is active for books until MAM.
- README + MEDIA.md notes added.

Follow-up: re-run AuthorSearch once the bibliographies have filled in; existing Grisham files on
disk are not yet matched (flat folder) — expect possible duplicate grabs.
