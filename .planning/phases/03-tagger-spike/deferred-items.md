# Phase 3 deferred items

Out-of-scope discoveries made while executing Phase 3 plans. Logged rather than fixed: each is
pre-existing, none was caused by the plan that found it, and each would change a shared script or
a stack this phase is contractually forbidden to edit (D-03).

---

## DEF-03-01 — `check-music-freeze.sh` cannot see a beets run inside `sabnzbd`

**Found by:** plan 03-04, task 2, 2026-09-03.
**Severity:** the phase's primary safety instrument has a blind spot over a *live* tagging path.

`scripts/check-music-freeze.sh:80` classifies tagger containers by name:

```bash
TAGGER_PATTERN='beets|soulbeet|wrtag|lidarr'
```

`sabnzbd` does not match. But sabnzbd runs beets as a post-processing script — a live path, not a
historical one:

| Evidence | Value |
|---|---|
| Post-proc beets config | `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets-config.yaml` (bind-mounted `rw` into the container in its own right) |
| Its beets database | `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb` |
| Its log | `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets.log` |
| Most recent run | **2026-09-03 20:30 UTC**, on `Garth Brooks - Fun (2020) FLAC`, outcome `skip` |
| That run's side effect | migrated `library.blb` and wrote **11 `.bak` files** — Pitfall 1, on a real database |
| sabnzbd's mounts | `/mnt/tank/downloads:rw`; **no `/mnt/tank/media` mount at any mode** |

**What this does and does not mean.** D-20 is **not** violated: sabnzbd cannot reach
`/mnt/tank/media` at all, so nothing here holds `rw` on the library, and
`check-music-freeze.sh` correctly returned `declared rw reaching Music: 0`. What *is* true is that
`tagger-class writers: 0` is reported by an enumeration that structurally cannot observe this
container, so for this one tagger the counter is silent rather than clean. That distinction is
exactly the "could not look" versus "nothing is wrong" rule in README § Health Checks.

It also matters to the project's core value: this is a **tagging path that is running unattended
today**, on the same `complete/nzb/music/` tree Phase 3 is sampling from. The `skip` outcomes in
`beets.log` name folders plan 03-03 selected as D-10 album candidates (`Garth_Brooks-Ropin_The_Wind`,
`Def.Leppard-CD.Collection`, `Ed.Sheeran-Play.Extended.Edition`).

**Why not fixed here.** `scripts/check-music-freeze.sh` is a shared harness folded into
`quick-health-check.sh`; widening `TAGGER_PATTERN` changes the pass/fail behaviour of every future
run in every plan of this wave, and plan 03-04's scope is standing up a measurement container.
Changing a shared assertion mid-wave, on a plan that did not cause the finding, is the kind of
edit that makes a later result unattributable.

**Suggested fix (Phase 4, alongside TAGR-03/TAGR-04):** classify by *behaviour* rather than by
container name — a container is tagger-class if it mounts a beets/wrtag config or database path,
not if its name matches a regex. At minimum, add `sabnzbd` to `TAGGER_PATTERN` and assert on the
mtime of all **four** beets databases, not on name matching.

---

## DEF-03-02 — the before-state instrument must glob `*.blb`, not just `library.db`

**Found by:** plan 03-04, task 2, 2026-09-03.
**Severity:** low, already corrected inside 03-04; recorded so later plans inherit the fix.

Plan 03-04's acceptance criterion reads *"the mtime of every `library.db` under `/mnt/fast/appdata/`
is unchanged"*. That glob finds **two** of this estate's **four** beets databases. The other two
are named `.blb`:

```
/mnt/fast/appdata/arrs/beets/config/musiclibrary.blb
/mnt/fast/appdata/arrs/beets/config/library.db
/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db
/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb      <- migrated 20:30, invisible to the glob
```

Four is consistent with Phase 1 plan 01-02's count; no new database has appeared. But the criterion
as written would have passed while a real beets database was being migrated three directories away.

**Inherited fix for plans 03-05 .. 03-11:** capture and compare
`find /mnt/fast/appdata \( -name '*.blb' -o -name 'library.db' \)`, and compare against the spike
container's `.Created` timestamp rather than against a wall-clock window — a window cannot
distinguish "this plan did it" from "something else did it while this plan ran".
