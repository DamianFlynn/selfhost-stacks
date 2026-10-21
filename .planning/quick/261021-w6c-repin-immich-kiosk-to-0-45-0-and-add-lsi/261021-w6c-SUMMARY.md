---
phase: quick-261021-w6c
plan: 01
status: complete
completed: 2026-10-21
requirements: [QUICK-261021-w6c]
key-files:
  modified:
    - stacks/selfhosted/immich/compose.yaml
    - renovate.json5
commits:
  - 56d6a7e8
  - e2ebe79a
---

# Quick 261021-w6c: immich-kiosk repin and Renovate rule for the LSIO arrs

immich-kiosk was pinned to `0.54.0`, a tag that does not exist on ghcr. It is now pinned to `0.45.0`, which the registry confirms exists. A versioning-only Renovate rule now covers the six LSIO arr images, so the `-lsNNN` suffix no longer blocks their updates. There are two commits on main and neither is pushed.

## Task 1: immich-kiosk repin (56d6a7e8)

The anonymous ghcr manifest probe returned these codes:

| tag | HTTP |
|-----|------|
| 0.45.0 | 200 |
| v0.45.0 | 404 |
| 0.54.0 | 404 (negative control) |
| v0.54.0 | 404 |
| 0.43.2 | 200 (positive control) |

The pin now uses the unprefixed `0.45.0`. Only the `image:` line changed, and the `# renovate:` comment is untouched. `docker compose config --no-interpolate -q` passed. The token was held in a shell variable only. The container was not redeployed and still runs 0.43.2.

## Task 2: Renovate rule for the LSIO arrs (e2ebe79a)

A new packageRule sits directly before "beets (1 of 2)". It lists 12 package names (the ghcr.io and lscr.io name for each of the six images). It sets `matchDatasources: ["docker"]` and the versioning regex, and has no matchUpdateTypes, automerge or addLabels.

The regex in the file decodes to exactly the literal regex in the plan (`decoded==literal: true`):

| sample | literal | from-file | major | minor | patch | build | revision |
|---|---|---|---|---|---|---|---|
| 4.0.16.2944-ls303 | true | true | 4 | 0 | 16 | 2944 | 303 |
| 4.0.20.3014-ls1 | true | true | 4 | 0 | 20 | 3014 | 1 |
| 6.4.4.10685-ls323 | true | true | 6 | 4 | 4 | 10685 | 323 |
| v1.5.6-ls340 | true | true | 1 | 5 | 6 | - | 340 |
| 5.1.2-r3-ls421 | true | true | 5 | 1 | 2 | - | 421 |
| 5.3.0_v2.1.2-ls484 | true | true | 5 | 3 | 0 | - | 484 |
| 3.1.0.4875-ls45 | true | true | 3 | 1 | 0 | 4875 | 45 |

The ordering check passes: `4.0.20.3014-ls1 > 4.0.16.2944-ls303` is true.

Validator output, renovate 44.176.1: `INFO: Config validated successfully against 1 file(s)`, exit 0. It passed both as a global config (the CI form, with the file argument) and as a repo config (`--no-global`, and also with no arguments).

## Deviations from Plan

**1. [Rule 3 - Blocking] The validator was run as `renovate@latest`, not as a bare `renovate`**
- The CI command as written, `npx --yes --package renovate`, picked up a stale npx-cached renovate **37.440.7**. That version rejects `docker-compose.managerFilePatterns` (exit 1).
- The same error appears on the unmodified `HEAD:renovate.json5`, so it existed before this change. It is caused by the cached version, not by the new rule. `managerFilePatterns` is a newer option that 37.x does not know about.
- The validator was re-run as `npx --yes --package renovate@latest` (44.176.1), which is the same package at its current version, and it passed. CI installs fresh, so it should resolve the current version as well. npm printed an EBADENGINE warning (node v26 against the required ^24.11) but the validator still ran.
- On this workstation, a bare `npx --package renovate` will keep giving a false failure until the npx cache is cleared.

## Self-Check: PASSED
- Both commits (56d6a7e8, e2ebe79a) exist on main, ahead of origin by 2, and are not pushed.
- Each commit touches only its own file. The pre-existing dirty and untracked paths are untouched.
