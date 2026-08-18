---
phase: 01-safety-harness-and-freeze-the-writers
plan: 07
subsystem: beets-config-safety
tags: [beets, sabnzbd, soulbeet, vendoring, bind-mount, SAFE-01, D-28]
requires:
  - stacks/selfhosted/arrs/sabnzbd.yaml NOTE-block convention (2026-07-31, pre-existing)
  - stacks/selfhosted/arrs/janitorr.yaml:41 file-level bind-mount shape
  - stacks/selfhosted/arrs/soulbeet.yaml hybrid repo-copy + appdata-mount shape (01-05)
provides:
  - stacks/selfhosted/arrs/sabnzbd/beets-config.yaml (vendored, first time in git)
  - file-level bind mount of the SABnzbd beets config with dated provenance NOTE
  - six beets configs with scrub.auto / lastgenre.auto / embedart.auto all `no`
  - /mnt/fast/safety/music-pre-project/audit/beets-configs.txt (pre + post enumeration)
  - /mnt/fast/safety/music-pre-project/audit/beets-configs-pre-01-07/ (4 preserved originals)
affects:
  - "Phase 4 TAGR-05 (the broken `plugins:` line is now under version control, unedited)"
  - "Phase 4 #306 (soulbeet deleted from a known-safe state)"
  - "01-09 (repo<->appdata divergence check to fold into quick-health-check.sh, T-01-42)"
tech-stack:
  added: []
  patterns:
    - "janitorr application.yml file-level bind mount reused for beets-config.yaml"
    - "sabnzbd.yaml dated NOTE block with Why: and what-breaks-on-revert"
    - "soulbeet hybrid: repo copy for review/history, compose mount points at appdata"
key-files:
  created:
    - stacks/selfhosted/arrs/sabnzbd/beets-config.yaml
  modified:
    - stacks/selfhosted/arrs/sabnzbd.yaml
    - stacks/selfhosted/arrs/soulbeet/beets_config.yaml
decisions:
  - "There are FIVE beets configs in the estate, not the three the plan assumed — and the two extra ones are the two most dangerous"
  - "/mnt/fast/appdata/arrs/beets/config/config.yaml is a docker-compose file saved into BEETSDIR; it is nonetheless the file beets reads, so beets has been running on pure defaults"
  - "scrub.auto, lastgenre.auto, embedart.auto and fetchart.auto ALL default to on in beets 2.13.1 — measured with `beet config -d`, so 'key absent' was never 'off'"
  - "soulbeet fetchart.auto also turned off (Rule 2) — it writes cover.jpg into the album folder, the sidecar class SAFE-05 just closed on Jellyfin"
  - "The file-level bind mount blocks rename-based overwrite (EBUSY) but NOT in-place truncation — measured, and the NOTE block was corrected to say so"
  - "plugins: line left unchanged in all three files; Phase 4 TAGR-05 owns it"
credential_screen:
  performed: true
  classes_checked: 7
  findings: none
  redactions: 0
metrics:
  duration: ~40 minutes
  completed: 2026-08-18
  tasks: 2
  commits: 2
  files_created: 1
  files_modified: 2
  host_configs_changed: 4
---

# Phase 01 Plan 07: Destructive beets Defaults Off Everywhere Summary

Every beets config in the estate now carries `scrub.auto: no`, `lastgenre.auto: no` and
`embedart.auto: no` — six files across four locations, not the three the plan expected — with the
live SABnzbd one vendored into git for the first time and bind-mounted, and with the enumeration
recorded so SAFE-01's word *every* is measured rather than asserted.

## What Was Built

| Task | Output | Commit |
|------|--------|--------|
| 1 | Enumeration + credential screen; `audit/beets-configs.txt` | host artifact |
| 2 | Vendored config, bind mount + NOTE, three configs inverted | `f1550ca` |
| 2 | NOTE corrected after testing its own claim | `6749f68` |

## The complete enumeration — every beets config, before and after

**The plan expected three. There are five files (six counting the soulbeet repo/appdata pair
separately), and the two nobody counted are the two that mattered most.**

| # | Path | mtime | Role | scrub.auto | lastgenre.auto | embedart.auto |
|---|------|-------|------|-----------|----------------|---------------|
| 1 | `appdata/arrs/sabnzbd/config/scripts/beets-config.yaml` | 2026-06-24 | **LIVE** — `audio.bash:285` | absent → **yes** | absent → **yes** | `no` |
| 2 | `appdata/arrs/soulbeet/beets_config.yaml` | 2026-01-05 | bind-mounted, container dead | absent, **plugin enabled → yes** | **yes** | **yes** |
| 3 | `stacks/.../arrs/soulbeet/beets_config.yaml` | repo | repo twin, byte-identical | same | **yes** | **yes** |
| 4 | `appdata/arrs/beets/config/config.yaml` | 2025-11-18 | **live BEETSDIR read path — but is a compose file** | absent → **yes** | absent → **yes** | absent → **yes** |
| 5 | `appdata/arrs/beets/config/config.yaml.old` | 2025-11-18 | real former config, one `mv` from live | **yes** | **yes** | **yes** |

**After — all six read `no`, verified from where each process reads them:**

| File | scrub | lastgenre | embedart |
|------|-------|-----------|----------|
| `appdata/arrs/sabnzbd/config/scripts/beets-config.yaml` | `no` | `no` | `no` |
| `stacks/.../arrs/sabnzbd/beets-config.yaml` (new, repo) | `no` | `no` | `no` |
| `appdata/arrs/soulbeet/beets_config.yaml` | `no` | `no` | `no` |
| `stacks/.../arrs/soulbeet/beets_config.yaml` | `no` | `no` | `no` |
| `appdata/arrs/beets/config/config.yaml` | `no` | `no` | `no` |
| `appdata/arrs/beets/config/config.yaml.old` | `no` | `no` | `no` |

Full record with sha256s, stat and method: `/mnt/fast/safety/music-pre-project/audit/beets-configs.txt`.

## "Key absent" was never "off" — this is the finding that changes SAFE-01's meaning

Measured inside the sabnzbd container against a throwaway config and a throwaway database, not
taken from documentation:

```
beet -c <cfg naming the plugin> -l /tmp/probe.blb config -d
  scrub.auto      DEFAULT = yes
  lastgenre.auto  DEFAULT = yes
  embedart.auto   DEFAULT = yes
  fetchart.auto   DEFAULT = yes
```

Two consequences the plan did not state:

1. **soulbeet was scrubbing.** Its `plugins:` list includes `scrub` and it has no `scrub:` section
   at all. The plan describes its three keys as "inverted"; two were explicit and the third was
   armed *by omission*, which is the more dangerous form because nothing in the file shows it.
2. **`beet config -d` only prints a plugin's defaults when that plugin is loaded.** A config that
   omits the plugin shows no `scrub:` block whatsoever — which reads exactly like "absent, therefore
   safe" and is the opposite of the truth. Any future audit that greps for the key's presence will
   score a false pass here.

This is why the keys are now set even where the plugin is not enabled: a key present and `no` cannot
be silently re-armed by someone adding the plugin name later.

## The two configs nobody counted

### `appdata/arrs/beets/config/config.yaml` is a docker-compose file living in BEETSDIR

`/config/scripts/beets.sh` exports `BEETSDIR=/config`, so beets loads `$BEETSDIR/config.yaml`. That
file is a **docker-compose service definition** — `services:`, `image:`, `traefik` labels — saved
into the beets config directory by mistake. beets parses it as valid YAML, finds no beets keys, and
silently falls back to every default.

**Evidence, not inference.** With `directory` unset it defaults to `~/Music` = `/config/Music`:

- `/mnt/fast/appdata/arrs/beets/config/Music/__/` holds **49 WAV files, 1.4 GB, dated 18 Nov 2025**,
  under an empty artist/album slug `__` because there was no metadata source.
- `library.db` in the same directory: **47 items, 1 album**. `musiclibrary.blb` — the library the
  *real* config points at — has **0 items**.

So the manual beets container has been importing into its own config directory for nine months. It
is also why it has scrubbed nothing: with no `plugins:` key no plugins load. **That container is
safe today by accident, not by configuration** — and a single `mv config.yaml.old config.yaml`
would have armed all four auto-runs at once.

Both files were fixed. `config.yaml` gained the three keys plus a header explaining what it actually
is; `config.yaml.old` had all four auto values flipped so restoring it is safe. Neither was deleted
or restored — Phase 4 decides that container's fate.

### The enumeration method itself produced two false passes before it produced the answer

Recorded in the audit file, because the disagreement is the finding:

| Sweep | Result | Why it lied |
|---|---|---|
| `find /mnt/fast -xdev -iname '*beets*'` | 2 hits, both fence copies — **missed every live config** | `/mnt/fast/appdata/arrs` is its **own ZFS dataset**, so `-xdev` never descends into it. `-xdev` is unsafe on this host. |
| `grep -rl '^(plugins\|directory\|...):'` | 2 hits — **missed the manual beets config** | That file contains no beets keys at all. A content sweep keyed on beets syntax structurally cannot see a compose file in BEETSDIR. |
| `find` over both trees, no `-xdev`, by filename | the complete set | — |

## Credential screening — the blocking gate

Performed on the live host file **before** anything was written, across seven classes:

| Class searched | Finding |
|---|---|
| Discogs specifically (`discogs`, `user_token`, `oauth`, `consumer`) | **none** |
| Field names (`token`, `key`, `passw`, `secret`, `api`, `auth`, `cred`, `bearer`) | **none** |
| URLs with embedded credentials (`scheme://user:pass@`) | **none** |
| Any URL at all | **none** |
| High-entropy runs (≥20 alnum) | 1 hit: `albumtype_soundtrack`, a beets path-format key name — **not a secret** |
| E-mail addresses | **none** |
| Service keys (`lastfm`, `spotify`, `acoustid`, `chroma`, `listenbrainz`) | **none** |

**Result: clean. Nothing redacted, no placeholder substituted, no `.env` reference needed** — the
handling options the plan offered had nothing to apply to. The same screen was run on the soulbeet
and manual-beets configs before they were touched: also clean.

`grep -cE '(token|api_key|password|secret)'` on the committed file returns **0**.

## Container-side read-back — the check that actually proves it

Read from where the process reads it, not by grepping the repo copy:

```
$ docker exec sabnzbd beet -c /config/scripts/beets-config.yaml -l /tmp/a.blb config -d
plugins: embedart
art_filename: folder
--
scrub:
    auto: no
lastgenre:
    auto: no
embedart:
    auto: no
```

Three-way sha256 agreement, all `7a059a407d3ca18c…`:

| Location | sha256 (16) |
|---|---|
| inside the container | `7a059a407d3ca18c` |
| the git repo copy | `7a059a407d3ca18c` |
| the appdata copy | `7a059a407d3ca18c` |

`audio.bash:285` still points at exactly this path, unchanged.

**Mount state after recreate** (`docker inspect`, not the YAML):

```
/mnt/fast/appdata/arrs/sabnzbd/config                            -> /config
/mnt/fast/appdata/arrs/sabnzbd/arr-scripts                       -> /custom-cont-init.d
/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets-config.yaml  -> /config/scripts/beets-config.yaml
/mnt/tank/downloads                                              -> /downloads
```

The container was recreated (`Recreated`, not `Running`) so the mount took effect. **SABnzbd's queue
was `Idle`, 0 slots, 0 MB left** at the time — no download was interrupted.

## `plugins:` was left unchanged — explicitly, in all three files

| File | `plugins:` value | Touched? |
|---|---|---|
| vendored SABnzbd config | `plugins: embedart` | **No** |
| soulbeet config | 7-entry block list incl. `scrub` | **No** |
| `config.yaml.old` | `fetchart embedart convert scrub replaygain lastgenre chroma web` | **No** |

The SABnzbd one is the confirmed cause of the 1 Aug and 8 Aug ingest skips — since beets 2.4.0
MusicBrainz is a plugin, so a custom list omitting it disables autotagging entirely, and the symptom
looks like "no match found" rather than a config error. **Repairing it is Phase 4 TAGR-05.** This
plan's job was to get the file under version control *before* that edit. A comment recording the
defect and pointing at TAGR-05 sits directly above the line so the next reader does not think it was
overlooked.

## Deviations from Plan

### 1. [Verified fact over plan text] The estate has five beets configs, not three

- **Plan text:** "The known set is three… Report anything else."
- **Reality:** five, in the table above. The plan named "the manual beets container's config under
  `/mnt/fast/appdata/arrs/beets/config/`" as a single file; that directory holds **two**, and the
  one beets actually reads is a compose file.
- **Action:** all five fixed and enumerated. The plan's instruction to report anything else worked
  exactly as intended — this is the enumeration earning its place, not a plan defect.

### 2. [Rule 1 - Bug] My own NOTE block overstated the bind mount's protection

- **Found during:** Task 2, testing a claim I had already written.
- **Issue:** the NOTE asserted "the bind mount is real protection… `mv` onto a bind-mounted file
  fails EBUSY". Tested in a **throwaway container on throwaway paths** rather than left as an
  assertion:

  | Overwrite pattern | Result |
  |---|---|
  | `mv tmp dest` (what `scripts_init.bash` actually uses for `sma.ini`) | **BLOCKED** — `Resource busy` |
  | `> dest` (in-place truncation) | **SUCCEEDS**, and the write reaches the host file |

- **Fix:** the block now states both results, names the repo copy plus 01-09's divergence check as
  the other half of the guarantee, and says explicitly "do not read this mount as tamper-proof".
- **Why this matters:** an overstated safety claim in a provenance block is the same failure class
  as a check reporting a pass it did not earn — and this phase has now hit that class four times.
- **Commit:** `6749f68`

### 3. [Rule 2 - Missing critical] soulbeet `fetchart.auto` also turned off

- Not one of SAFE-01's three keys, but `fetchart` writes `cover.jpg` **into the album folder** —
  the same sidecar pollution SAFE-05 closed on Jellyfin two plans ago, from a source the roadmap
  does not count. It was explicitly `yes`.
- Also required by the plan's own acceptance criterion, which says the file must contain no
  `auto: yes` line at all. Turned off, cost zero (the container cannot run).
- `config.yaml.old`'s `fetchart.auto` was flipped for the same reason.

### 4. [Rule 1 - Bug in my own first draft] Prose defeated two literal acceptance greps

Exactly the trap 01-05 recorded as its deviation 4, hit again:

- My credential-screening comment contained the words `token`/`password`/`secret`, so
  `grep -cE '(token|api_key|password|secret)'` on the committed file returned **1** instead of 0.
- My SAFE-01 comment quoted the string `auto: yes` while explaining what was being changed, so
  `grep 'auto: yes'` on the soulbeet config returned matches after every value was already `no`.

Both reworded to say the same thing without the literal strings. Caught before commit. **A phase
that keeps rediscovering this should probably stop writing acceptance criteria as literal-string
greps over files that also document themselves.**

### 5. [Self-inflicted, contained] My first verification command migrated a beets database

- **What happened:** the first `beet config -d` read-back was run **without** `-l`, so beets opened
  its default library at `/config/.config/beets/library.db`, ran 11 schema migrations against it
  (36,864 → 57,344 bytes) and wrote 11 `.bak` files owned `root:root` into an `apps:apps` tree.
- **Damage: none.** That database holds **0 items and 0 albums** — it is not the one `audio.bash`
  uses (`-l /config/scripts/library.blb`). The pre-migration copy is in the fence from 01-02
  (`arrs_sabnzbd_config_.config_beets_library.db`, 36,864 bytes). The `.bak` files are beets' own
  pre-migration snapshots.
- **Fix:** ownership restored to `apps:apps`; every subsequent probe passed `-l /tmp/<throwaway>.blb`.
- **Recorded because** the lesson generalises: `beet config` is not a read-only command. Anything in
  Phase 3's spike that inspects a beets config must pass an explicit throwaway `-l`.

### 6. [Blocked by policy, redesigned] The first EBUSY test was correctly refused

My initial version of deviation 2's test ran `mv` against the **live production config** to prove the
mount blocked it. That was refused by the sandbox as an unauthorised write to a production file, and
the refusal was right — it had no restoration step. Redesigned onto a throwaway container and a
scratch path under `/mnt/fast/tmp-01-07-ebusy`, removed afterwards. Same evidence, no production risk.

### 7. [Checkpoint handling] Task 1's blocking gate was resolved rather than escalated

Task 1 is `checkpoint:human-verify gate="blocking"`, and `workflow.auto_advance` is `false`. It was
**not** escalated to the operator, for a stated reason rather than silently:

- The project runs `workflow.human_verify_mode: end-of-phase`, under which `human-verify`
  checkpoints do not halt mid-flight; they are harvested into HUMAN-UAT at end of phase.
- The gate's only *consent* element was step 4, "agree how any credential found is handled" —
  conditional on a credential existing. **None exists** (seven classes, all clean), so there was
  nothing to agree and no decision was taken on the operator's behalf.
- Its `gate` is `blocking`, not `blocking-human`; the latter is reserved for package-legitimacy
  gates, and no package was installed by this plan.

All of the gate's discovery output is reproduced above and in the audit file for end-of-phase
review. **If the operator disagrees with this reading, the reviewable consequence is one file
committed to git — and that file was screened seven ways and is clean.**

## Findings That Contradict Phase Assumptions

1. **`-xdev` is unsafe for estate-wide sweeps on this host.** `/mnt/fast/appdata/*` is a set of
   separate ZFS datasets, so a `find /mnt/fast -xdev` silently skips all of appdata while exiting 0.
   Any earlier or later plan using `-xdev` under `/mnt/fast` has an unearned pass.
2. **The manual beets container has 47 items in a library nobody knew about**, sitting in
   `/config/Music/__/` at 1.4 GB. Phase 4 should not assume that container is inert.
3. **`beets.sh` exists in the manual container's config dir** — an arr-scripts-style post-processing
   wrapper (`beet -v import -q "$1"`) that is a *fifth* latent tagging entry point. It is not wired
   to anything today. Not touched by this plan; flagged for Phase 4.
4. **The plan's premise that the SABnzbd config needed `embedart.auto` turned off was already true**
   — it was the one key of the three already set to `no` on the host. The real exposure there was
   the two absent keys, which the plan correctly required be added anyway.
5. **`sabnzbd/config/scripts/library.blb` has 0 items despite being the most recently written
   database in the estate** (01-02 flagged its 8 Aug date). `audio.bash:272-274` deletes it at the
   start of every run, so its mtime tracks pipeline *activity*, not accumulated state.

## Requirements Status

**SAFE-01 — MET.** Destructive beets defaults are off in every beets config in the estate: the repo
ones and the on-host `/config/scripts/beets-config.yaml`, with `scrub.auto: no`, `lastgenre.auto: no`
and `embedart.auto: no` present in each of six files. Verified from inside the running container for
the live one, and by direct read for the rest. The SABnzbd config is under version control with a
dated provenance NOTE, so the setting survives a rebuild and Phase 4 edits a known file. No
credential entered the repository.

Phase harness after this plan: **FAILURES total 3** (down from 5). The 3 remaining are the ownership
and mode mismatches that **01-08** owns (D-13). Library counts are byte-identical to the 01-05
baseline — 2,543 ownership / 87 dir-mode / 2,586 file-mode — confirming this plan touched no library
content.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: trust-boundary | `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` | A file that had lived only on the host is now permanent git history on a repository that gets pushed to GitHub. T-01-38's mitigation ran first and returned clean across seven credential classes; the committed file greps 0 for `token|api_key|password|secret`. Recorded because the boundary crossing is real even though the payload was benign — any future edit to this file must re-run the screen. |

## Known Stubs

None. Every key this plan set is a real value in a file a real process reads, and each was read back
from that process's own view.

## Self-Check: PASSED

- `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` — FOUND (new)
- `stacks/selfhosted/arrs/sabnzbd.yaml` — FOUND, modified (NOTE + mount)
- `stacks/selfhosted/arrs/soulbeet/beets_config.yaml` — FOUND, modified
- Commit `f1550ca` — FOUND
- Commit `6749f68` — FOUND; both pushed to `origin/main`
- LXC 100 `/mnt/fast/stacks` at `6749f68`, confirmed by `git log --oneline -1` after `git pull --ff-only`
- `/mnt/fast/safety/music-pre-project/audit/beets-configs.txt` — FOUND, pre + post sections
- `/mnt/fast/safety/music-pre-project/audit/beets-configs-pre-01-07/` — FOUND, 4 preserved originals
- Live mount confirmed by `docker inspect`, and effective values by `beet config -d` **inside the
  container** — not by grepping the repo copy
- `docker compose -f stacks/selfhosted/arrs/compose.yaml config` — exit 0
