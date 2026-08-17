# Pitfalls Research

**Domain:** Self-hosted music library — bulk autotagging, filesystem organisation, multi-consumer media serving
**Researched:** 2026-08-17
**Confidence:** HIGH on tool behaviour (beets/wrtag/Jellyfin/Music Assistant docs + source verified), MEDIUM on this estate's ZFS/HAOS specifics (documented behaviour, not yet observed here), MEDIUM on abandonment analysis (reasoned from this project's own three-failure history plus community evidence, not from formal post-mortems)

> **Scope note.** `stacks/selfhosted/arrs/beets.md` already documents: `rsync -a` failing on `tank`, ZFS async space free, Jellyfin `SaveLocalMetadata`, `import.move: yes`, the missing `preferred.countries`, the missing `fromfilename`/`edit` plugins, DJ services not being in MusicBrainz, and the 85 shared folder names. Those are **not** repeated here except where this research adds something materially new. Everything below is new to this system.

---

## Phase vocabulary used in this document

Phase numbers are indicative — the roadmap owns final ordering. Themes referenced:

| Ref | Theme |
|---|---|
| **P1** | Safety harness — backups, config hardening, freeze the consumers, dry-run discipline |
| **P2** | Retire the dead taggers — one tool, one database |
| **P3** | Tagger spike — bake-off on a real sample |
| **P4** | Bucket D triage — junk, `_FAILED_`, `.rar`, misfiled non-music |
| **P5** | Bucket A import — mainstream albums, end-to-end |
| **P6** | Music Assistant — second consumer verified |
| **P7** | Ingest path — the one pipeline new downloads go through |
| **P8** | Bucket B — the *Now!* series |
| **P9** | DJ content — own path, tag normalisation, scan extraction |
| **P10** | Duplicate reconciliation |

**Hard ordering constraints derived from the pitfalls below:** P1 before everything. P4 before P5 (junk in the sample corrupts the spike's evidence). P6 must be proven on a handful of albums *before* P5 scales, not after — see Pitfall 12. P2 must complete before P7, or you build the fourth half-pipeline.

---

## Critical Pitfalls

### Pitfall 1: `scrub` strips the only surviving metadata before beets writes its own

**What goes wrong:**
`soulbeet/beets_config.yaml` enables the `scrub` plugin with no `scrub:` section, so `auto` defaults to **yes**. Combined with `import.write: yes` (also set), beets **removes the tag block entirely and then writes back only the fields it tracks in its own database**. Anything beets does not model — comments, `TXXX` frames, original catalogue numbers, DJ service issue numbers, BPM fields, embedded cue/tracklist text, ReplayGain, ratings — is gone from the file. The strip happens *before* the write, so there is no rollback.

For bucket A this is cosmetic. For bucket C it is **catastrophic and irreversible**. `beet import -A` (the approach `beets.md` prescribes for DJ content) preserves the *field mapping* beets read — but `scrub` still deletes every field beets did **not** read. The DJ releases are the exact content where the file's own tags are the only source of truth, because Mastermix/DMC/Music Factory are not in MusicBrainz. The residual evidence needed to *repair* the broken field mapping documented in PROJECT.md (issue numbers, BPM, original series name) frequently lives in exactly those untracked fields.

**Why it happens:**
`scrub` reads as hygiene ("clean tags"). Nobody reads the plugin docs before enabling it because the name sounds harmless, and the destructive behaviour is the *default*, not an opt-in.

**How to avoid:**
```yaml
scrub:
  auto: no        # keep the `beet scrub` command available, never automatic
```
Set this in P1, before any import runs. Then, before touching bucket C at all, capture a full tag dump as a text artefact:
```bash
# one-time, non-destructive, ~800 files
find /mnt/tank/downloads/complete/nzb/dj-mixes -type f \
  \( -name '*.mp3' -o -name '*.flac' -o -name '*.m4a' \) -print0 \
| xargs -0 -n1 ffprobe -v quiet -show_entries format_tags -of json \
> /mnt/fast/appdata/music-tag-snapshot-dj-mixes.json
```
That JSON is the recovery artefact. It costs one command and makes every subsequent DJ tagging experiment reversible.

**Warning signs:**
- Post-import, `beet ls -f '$comments'` is empty across the board where source files had comments.
- Files shrink noticeably relative to source (tag block gone, art re-embedded smaller).
- Any bucket-C release where you can no longer tell which Mastermix issue it came from.

**Phase to address:** **P1** (config change + tag snapshot). Re-verify at **P9**.

---

### Pitfall 2: `lastgenre: auto: yes` and `embedart: auto: yes` are silent overwrites at scale

**What goes wrong:**
The same config runs `lastgenre` with `auto: yes` and `source: album`. Every imported album gets its genre replaced by whatever Last.fm's top album tag is. Last.fm album tags on compilations are noise ("seen live", "awesome", "00s"). For the DJ content — where the existing genre field is often the *only* useful classification (e.g. "R'n'B", "Yacht Soul") — this replaces good data with crowd-sourced junk across the whole import, in one pass, with no prompt.

`embedart: auto: yes` combined with `fetchart: cautious: yes` will embed fetched art into every file. On a wrong-release match this bakes the wrong cover into the audio files themselves, which survives a later re-tag unless explicitly cleared.

**Why it happens:**
Both are "enrichment" plugins and read as free upside. Their cost only shows up on content where the incoming metadata was *better* than the online source — which is precisely the atypical content in this backlog.

**How to avoid:**
- `lastgenre: auto: no` for the first passes. Run `beet lastgenre` as a deliberate follow-up query against bucket A only (`beet lastgenre albumartist:'Taylor Swift'`), never library-wide, never on bucket C.
- Keep `fetchart` but set `embedart: auto: no` until match quality is trusted. Folder-level `cover.jpg` is reversible; embedded art is not, cheaply.

**Warning signs:**
- `beet ls -a -f '$album — $genre'` shows the same two or three genres across unrelated albums.
- Album art in Jellyfin is right at folder level but wrong inside the player (embedded art wins in most clients).

**Phase to address:** **P1**.

---

### Pitfall 3: `-q` quiet mode auto-accepts, and `quiet_fallback: asis` is the trap fix

**What goes wrong:**
`audio.bash` imports with `-q`. In quiet mode beets **auto-applies any match at or below `strong_rec_thresh` with no prompt** and skips everything else. The config sets `strong_rec_thresh: 0.04`, which is the beets **default**, not a strict value — `beets.md` describes it as "strict-ish", which overstates it.

The `skip` lines logged for the 1 Aug and 8 Aug jobs are quiet mode working correctly: no strong match, so nothing happened. The obvious-looking fix is `quiet_fallback: asis` (or `--quiet-fallback ASIS`), which makes beets import *everything* regardless of match quality, as-is. On this backlog that means 7,451 untagged files entering the library with filename-derived garbage, moved out of the source, in one unattended run. This is the single most plausible way this project destroys itself while trying to unblock itself.

**Why it happens:**
The symptom ("it says skip") looks like a configuration problem. `quiet_fallback` is a one-line config change that makes the symptom disappear. It is the wrong layer — the skips are a *content* problem, not a config problem.

**How to avoid:**
- Never set `quiet_fallback: asis` on a path that also has `move` enabled. If as-is import is genuinely wanted, use `beet import -A -C -M` (as-is, no copy, no move) so files stay put and only the database changes.
- Treat the `-q` skips as the correct outcome. The design fix is that unattended ingest (P7) handles only high-confidence content and *routes* the rest to a review queue — not that it lowers its standards.
- Raise, don't lower: for unattended ingest consider `strong_rec_thresh: 0.02` so auto-accept means genuinely certain.

**Warning signs:**
- Import log volume jumps from a handful of `skip` lines to thousands of successful imports overnight.
- New albums appear in Jellyfin with artist names that look like directory names or scene release tags.

**Phase to address:** **P1** (understand it), **P7** (design the routing instead of the shortcut).

---

### Pitfall 4: `audio.bash` deletes its own database each run — no incremental, no duplicate detection, no audit trail

**What goes wrong:**
The sabnzbd post-processing beets `rm`s `library.blb` every run. Consequences that compound:

1. **`import.incremental` can never work.** Every run treats every directory as new.
2. **`duplicate_action` can never fire.** beets' duplicate detection is a *database* query. With an empty database there are no duplicates by definition, so `duplicate_action: ask` (the default) is dead code on this path.
3. **There is no record of what it did.** After the run, nothing on disk says which files this pipeline touched or what it matched them to. If it makes a wrong-release match, you cannot query for it afterwards.
4. **Re-processing the same download twice produces two library entries.** beets does not clobber (verified in source: `Item.move_file` calls `util.unique_path`), so you get `01 Title.mp3` and `01 Title.1.mp3` side by side rather than an overwrite. Quieter than a crash, and far harder to notice.

**Why it happens:**
Stateless-by-design is a reasonable instinct for a post-processing hook. It is wrong here because beets' safety features are all state-dependent.

**How to avoid:**
Give the ingest path a **persistent** database on `/mnt/fast/appdata`, or take it out of the tagging business entirely and have it only move downloads into a staging directory that the one real pipeline consumes. The second option is cleaner and matches the "exactly one pipeline" core value.

**Warning signs — run this now and after every bulk operation:**
```bash
find /mnt/tank/media/Music -regextype posix-extended \
  -regex '.*\.[0-9]+\.(mp3|flac|m4a|wav|aac|ogg|wma)$' | head -50
```
Any hit is a beets destination collision — i.e. two tools or two runs racing on the same tree.

**Phase to address:** **P2** (decide its fate), **P7** (rebuild it properly).

---

### Pitfall 5: Four databases, one destination tree

**What goes wrong:**
`beets.md` flags "two beets, one library". It is actually **four** state stores writing to or claiming authority over `/mnt/tank/media/Music`:

| Store | Owner | Knows about |
|---|---|---|
| `arrs/beets/config/library.db` | manual beets | the 34 GB tagged library (last write Nov 2025) |
| `soulbeet/data/beets_library.db` | soulbeet | nothing (never deployed) |
| `media/wrtag/data/wrtag.db` | wrtag | its own job queue (idle since Jan 2026) |
| `library.blb` | `audio.bash` | nothing (deleted each run) |

The failure modes are not symmetric and not all obvious:

- **`beet update` prunes silently.** If another tool moved a file that manual-beets has in `library.db`, `beet update` on that query drops the item from the database. The file is fine; the *record* is gone, and with it the `mb_albumid` that would let you re-derive what it was.
- **`beet move` on stale entries reorganises files another tool placed.** Nobody asks for this; it happens as a side effect of "let me tidy up the paths".
- **`%aunique{}` cannot disambiguate across databases.** Its whole purpose is to add a disambiguator when *this* database already holds a same-named album. With four databases, two genuinely different releases with the same `$albumartist/$album` land on the same path and beets appends `.1` — you get a merged pseudo-album containing tracks from two different releases in one folder.
- **`duplicate_action` is per-database.** Cross-tool duplicates are invisible to all four.
- **wrtag and beets disagree on layout by design.** The current `WRTAG_PATH_FORMAT` sends **everything** to `/music/library/Compilations/...` regardless of release type, while beets sends non-comps to `$albumartist/$album`. Running both over the same content produces two copies of the same album under two different paths, and neither database knows about the other's copy.

**Why it happens:**
Each tool was added to solve a specific problem, and each defaults to owning its own state. Nothing warns you that the destination is shared.

**How to avoid:**
P2 is not optional cleanup — it is a correctness prerequisite. Concretely: pick one tool, then **remove the container definitions and the volume mounts** for the others so they cannot be started by accident. Leaving a stopped container with `/mnt/tank/media/Music` mounted rw is a loaded gun; the estate has already demonstrated (see the `created`-state blind spot in project memory) that "not running" is not a state anyone reliably checks.

**Recovery cost if it happens anyway: HIGH.** There is no merge tool. You re-import one side with `beet import -A -C -M` (catalogue in place, no file movement) to rebuild a single database from the tree as it stands, then accept whatever tag quality is already there. That is why PROJECT.md correctly lists reconciling the two `library.db` files as out of scope.

**Warning signs:**
- The `.1`/`.2` suffix search from Pitfall 4 returns anything.
- `Compilations/` and `<Artist>/` both contain the same album.
- `beet stats` album count diverges from `find /mnt/tank/media/Music -mindepth 2 -maxdepth 2 -type d | wc -l`.

**Phase to address:** **P2**, and it must complete before **P5**.

---

### Pitfall 6: `wrtag sync` on a shared library, and `move` deleting the DJ cover scans

**What goes wrong:**
Two distinct wrtag hazards, both documented upstream, both live in this repo's config:

**(a) `sync` is explicitly destructive on foreign libraries.** The wrtag README states: *"As the `sync` command is non-interactive, when used incorrectly it can be destructive. Only use `sync` on a library whose contents have been populated by `copy` or `move`."* `/mnt/tank/media/Music` was populated by **beets**, plus Jellyfin's `.nfo`/`.jpg` sidecars. It is exactly the library the warning is about. `sync` recurses from the path-format root, re-derives every leaf directory's correct location, and reorganises — non-interactively, across the 34 GB Jellyfin source.

**(b) `move` "always cleans up the source directory".** wrtag deletes source folders after a successful move and validates that "no orphan folders are left". Files not matched and not listed in `-keep-file` are **not carried over**. The 54 cover-scan images across 27 `dj-mixes` folders — which PROJECT.md correctly identifies as *more reliable than any autotagger* because they carry full tracklistings — are non-music files. Without an explicit `-keep-file` rule they are dropped, and the source folder they lived in is removed. That is the single most valuable irreplaceable asset in the entire backlog, deleted by a tool doing exactly what it says it does.

**Why it happens:**
`sync` reads like `rsync`. And `-keep-file` is opt-in — the safe default would be the other way round.

**How to avoid:**
- If wrtag loses the P3 spike: remove the container definition and the `/mnt/tank/media/Music` mount. Do not leave it idle-but-mounted (it has been idle-but-mounted since January).
- If wrtag wins: point its library root at a **fresh empty directory**, migrate deliberately, and never run `sync` against a tree beets touched. Use `-dry-run` on every first run of any new path format.
- **Before any DJ content is processed by anything**, copy the scans out to a location no tagger has write access to:
  ```bash
  rsync -rlt --no-p --no-o --no-g --include='*/' \
    --include='*.jpg' --include='*.jpeg' --include='*.png' --exclude='*' \
    /mnt/tank/downloads/complete/nzb/dj-mixes/ /mnt/tank/archive/dj-scans/
  ```
  (`-rlt --no-p --no-o --no-g` per the known `tank` ACL constraint.)

**Warning signs:**
- `wrtag.db` mtime changes when nobody ran anything.
- Source folders under `dj-mixes` disappearing.
- Any wrtag command run without `-dry-run` first.

**Phase to address:** **P2** (retire or isolate), **P9** (scan preservation must precede any DJ processing).

---

### Pitfall 7: The wrtag path-format pin is a live upgrade trap, not just a version lock

**What goes wrong:**
The image is pinned `v0.20.0` with a Renovate rule blocking upgrades, because v0.30.0 carried a breaking path-format change:

| v0.2x | v0.30.0 |
|---|---|
| `.TrackNum` | `.Track.Position` (real per-disc MusicBrainz position) |
| `len .Tracks` | `.Media.TrackCount` (per-medium, not total) |
| `.Tracks` | *removed* |
| — | `.Media`, `.Media.Position` (new) |

The current `WRTAG_PATH_FORMAT` in `music/wrtag.yaml` already uses `.Track.Position` and `.Media.Position` — i.e. **it is written in v0.30+ syntax while the image is pinned to v0.20.0**. Either the format has been updated in anticipation and the container has been failing to render paths since, or wrtag is running with a format it cannot evaluate. Either way, "wrtag idle since Jan 2026" may not be neglect — it may be broken. Upstream is now at v0.33.0 (Jul 2026), three minors past the pin.

**Why it happens:**
A Renovate pin with an explanatory comment feels like a resolved decision. It is actually a deferred one, and the config drifted underneath it.

**How to avoid:**
In **P3**, before spending any spike effort on wrtag, run `docker logs wrtag` and one `wrtag move -dry-run` against a single throwaway album. If the path format does not render, that is the spike result for wrtag — no further evidence needed. Note also v0.33.0's `docker: don't recursive chown` fix, which is directly relevant to this estate's ZFS ACL situation.

**Warning signs:**
- wrtag container up but log shows template evaluation errors.
- `wrtag.db` has zero completed jobs despite the container running for seven months.

**Phase to address:** **P3** — as a five-minute disqualifier, not a research project.

---

### Pitfall 8: `preferred.countries` does not do what it looks like it does

**What goes wrong:**
`beets.md` prescribes `match.preferred.countries` for the *Now!* problem. That is correct but insufficient, and the gap matters because bucket B is 45 GB of it. `preferred` applies a **distance penalty** — a tiebreaker. It cannot beat a candidate that matches better on track titles, count and duration. For the *Now!* series the UK and US volumes with the same number have entirely different tracklists, so whichever side the ripper's existing tags lean toward will usually already win on content, and the country nudge changes nothing.

Two syntax traps compound it:
- MusicBrainz stores the UK as **`GB`**. `countries: ['UK']` silently matches nothing. Entries are regexes, so the safe form is `['GB|UK', 'US']` — and note the documented example puts them in preference order, first entry wins.
- `preferred.original_year: yes` is a separate switch and is often the more decisive one for numbered series.

**Why it happens:**
The option name reads like a filter. It is a weight.

**How to avoid:**
The real disambiguator is `musicbrainz.extra_tags`, which feeds existing tag values into the MusicBrainz *search query* rather than post-scoring the results:
```yaml
musicbrainz:
  extra_tags: [catalognum, country, label, media, year, barcode]
match:
  preferred:
    countries: ['GB|UK', 'US']
    original_year: yes
```
Caveat with teeth: `extra_tags` only helps where the source files *already carry* those tags. For untagged NZB rips it contributes nothing, and the honest answer for bucket B is manual: `beet import -t`, and press `I` to paste the MusicBrainz release ID when it guesses wrong. Budget for that rather than hoping config solves it.

**Do not reach for `chroma`/AcoustID as the fix.** Fingerprinting is the intuitive answer and it is counterproductive here: beets issue #360 documents chroma *degrading* compilation matching — contributing zero album candidates while still inflating the distance (0.0018 → 0.1359 in the reported case), which demotes a strong recommendation to medium and opens the field to wrong candidates. Compilations are chroma's worst case, and bucket B is entirely compilations.

**Warning signs:**
- Imported *Now!* volume where track 1 is right and track 7 is not — the classic partial-overlap signature of a wrong regional edition.
- `beet ls -a -f '$album | $country | $mb_albumid'` shows `US` on volumes 1–30 (US series started 1998, so any US match on an early volume number is wrong by construction).

**Phase to address:** **P1** (config), **P8** (execution, with a manual budget).

---

### Pitfall 9: Detecting a wrong-release match *before* it is committed, and after

**What goes wrong:**
At single-album scale you read the diff at the prompt. At 620-album scale nobody does, and wrong matches accumulate invisibly because a wrong match produces a *complete, plausible, fully-populated* album — it just is not the one you have. There is no error state to alert on.

**How to avoid — pre-commit:**
1. `beet import --pretend` first. It prints what would be imported without doing it, which catches directory-grouping errors (the 115-album folder problem) before any file moves.
2. `beet import -t` for anything in buckets B and C. Timid confirms every action including good matches.
3. Read the **track count and total duration** line, not the title. A wrong-release match on a compilation almost always differs in track count or in one track's duration by >10 s. Title lists are long and eyes slide over them; two numbers do not.
4. Set `import.log` and actually parse it. beets writes one line per non-trivial outcome (`skip`, `asis`, `duplicate`) — this is the audit trail the whole project depends on and `audio.bash` currently throws away.

**How to avoid — post-commit detection sweep** (run after every bulk batch, before moving on):
```bash
# 1. destination collisions -> two tools/runs racing
find /mnt/tank/media/Music -regextype posix-extended \
  -regex '.*\.[0-9]+\.(mp3|flac|m4a)$'

# 2. albums whose file count != MusicBrainz track total
beet ls -a -f '$albumartist|$album|$tracktotal|$mb_albumid'

# 3. albums with no MusicBrainz id at all (as-is imports that slipped through)
beet ls -a mb_albumid:: -f '$albumartist — $album'

# 4. regional sanity for bucket B
beet ls -a album:'Now That' -f '$album | $country | $year'
```

**Recovery after a wrong match — cost depends entirely on one setting:**
- **If `copy`:** LOW. `beet remove -a <query>` (no `-d`), delete the copies under `/mnt/tank/media/Music`, re-import from the untouched source. This is the entire argument for the copy-first constraint in PROJECT.md.
- **If `move`:** HIGH. There is no undo. Files are in the destination under wrong paths with wrong tags, and if `scrub` ran the original tags no longer exist anywhere. Best case is restoring the pre-run `library.db` backup and running `beet move` — which restores *paths* but not tags.

**Phase to address:** **P1** (log + detection sweep as standing practice), **P5** (first real use).

---

### Pitfall 10: Jellyfin's `.nfo` sidecars become the authority and outlive the files they describe

**What goes wrong:**
`beets.md` notes that `SaveLocalMetadata: true` causes `.nfo`/`.jpg`/`.lrc` to appear. What it does not cover is what those files then *do*:

1. **Local metadata wins.** Jellyfin's docs state local `.nfo` metadata cannot be disabled and takes priority over remote providers. Multiple open issues (#13655, #16356, discussion #12923) report NFO data winning over freshly re-tagged embedded tags, and Jellyfin refusing to pick up NFO edits on rescan. **Consequence: re-tag a file in place and Jellyfin may keep showing the old metadata forever**, surviving rescan, library removal, and container restart. Reported workaround is to delete the `.nfo` and Jellyfin's `config/metadata/artists/<name>` cache folder, then rescan.
2. **They are orphaned by moves.** beets moves *music files* (plus its own tracked album art). `.nfo`, `.lrc` and stray images are left behind. Re-tagging an album into a corrected path leaves a directory containing only Jellyfin's sidecars — and Jellyfin has **no orphan-file cleanup task** (open feature request #3121). You accumulate ghost folders that scan into ghost albums.
3. **beets' `clutter` option is the sharp edge on the other side.** `clutter` (default `["Thumbs.DB", ".DS_Store"]`) lists filenames beets will delete when pruning an emptied directory. Adding `*.nfo` or `*.jpg` to it stops the orphaning — and also means beets deletes Jellyfin's saved artwork and any DJ cover scan sitting in a source folder. Do not add image globs to `clutter` while bucket C is unprocessed.

**Additionally: moving files loses user state.** Jellyfin keys items to paths. Moving a library reliably produces duplicated items, emptied playlists (playlist XML under `data/playlists/` stores paths), and lost play counts/favourites. Open issues #4728, #12297, #11625 and #14589 all describe variants. This matters because the *whole project* is a large, deliberate move.

**How to avoid:**
- **Turn `SaveLocalMetadata` off for the Music library for the duration of the project.** Turn it back on, if wanted, only once the tree is stable. This one change removes a whole class of problem.
- Pause Jellyfin's **scheduled library scan** during bulk operations. Scanning a tree mid-move is how you get the duplicate-item state.
- Back up Jellyfin's database before the first bulk batch. It is small, and it is the only route back to play counts and playlists.
- Verify Jellyfin state *after* the first small batch, not after the whole import.

**Warning signs:**
- Album shows corrected tags in `beet ls` and stale ones in the Jellyfin UI.
- Directories under `/media/Music` containing only `.nfo`/`.jpg` and no audio.
- Playlist track counts drop after a scan.

**Phase to address:** **P1** (disable `SaveLocalMetadata`, pause scans, back up the DB), **P5** (verify).

---

### Pitfall 11: Music Assistant cannot see a folder mounted into Home Assistant's `/media`

**What goes wrong:**
PROJECT.md assumes the Music Assistant mount will be added "through Home Assistant's own storage configuration". The Music Assistant filesystem-provider docs say, verbatim:

> "For Home Assistant OS only the `/media` folder can be accessed. […] It is not possible to mount a folder from Home Assistant into the `/media` path."

A community maintainer separately flags the failure mode even where a mount does appear: MA cannot tell whether the mounted folder is *available*, so it can begin a sync while the share is still mounting — producing a partial library, or a library that empties itself after a NUC reboot.

**Why it matters here:** the Music Assistant requirement is a **stated phase-completion gate** in PROJECT.md ("a phase is only done when the content is visible in both"). If the mount strategy is wrong, the gate cannot be met and the discovery happens at the *end* of a phase, after the import work is done. That is precisely the shape of failure that produces abandonment.

**How to avoid:**
Use the **"Filesystem (remote share)"** provider (SMB/CIFS, NFS or WebDAV) pointed directly at the storage, rather than the "Filesystem (local disk)" provider pointed at an HA mount. This avoids both the `/media` restriction and the mount-timing race. Confidence MEDIUM — HA's Network Storage feature may in practice expose media mounts to add-ons; the docs and the community guidance disagree. **Resolve this empirically and early**, with three albums, not at the end of a 600-album import.

**Three further MA constraints that will bite this specific content:**

| Constraint | Impact here |
|---|---|
| **"Folders commencing with an underscore will be ignored."** | `_FAILED_`, `_UNPACK_` — fine. But any `_dj-mixes` or `_staging` naming convention silently hides content. Do not prefix library directories with `_`. |
| **Non-UTF-8 filenames are skipped during sync with only a log warning.** | Scene/NZB rips routinely carry latin-1 names. Files land on disk, Jellyfin plays them, MA silently omits them. Two consumers disagreeing with no error is the hardest bug class in this project. |
| **Emoji and special characters unsupported on SMB/CIFS shares (kernel limitation); items skipped.** | Constrains the remote-share option; argues for NFS over SMB. |
| **"MA requires the Album Artist tag to be set."** | `beet import -A` on DJ content preserves whatever mapping exists — and PROJECT.md's sample shows `album="VA"`, `artist="R'n'b Hits…"`. No `albumartist` at all in some cases. MA will fall back to Various Artists / folder name. **Setting `albumartist` is not cosmetic; it is an MA correctness requirement.** |

**Warning signs:**
- MA album count materially below Jellyfin's for the same tree.
- MA logs showing skipped-file warnings during sync (check them; they are warnings, not errors).

**Phase to address:** **P6**, executed as a *thin early spike* (three albums, both consumers verified) rather than a late integration phase.

---

### Pitfall 12: Music Assistant never purges stale entries, and the recovery has a one-shot window

**What goes wrong:**
Once MA has indexed the tree, re-tagging or moving files underneath it leaves stale library entries that **rescanning does not remove**. Issue #4877 ("Deleted media from music providers is never removed from library") and #4846 (folder rename, forced sync completes, stale entries remain) both document this. Stale entries then cause playback errors when the queue advances to a track whose file is gone.

The documented recoveries, in escalating cost:

| Recovery | Cost | Note |
|---|---|---|
| `REFRESH ITEM` on the ⋮ menu | LOW | Re-adds the item, overwriting existing data. `UPDATE METADATA` does *not* do this — it only adds. |
| `REMOVE FROM LIBRARY` per item | LOW per item, unusable at scale | — |
| Remove the filesystem provider, **wait for cleanup to complete** | MEDIUM | **If MA is restarted before cleanup finishes, recovery is no longer possible.** Watch the logs. |
| Settings → System → Music → Advanced → **Reset Library Database** | HIGH | Loses MA-side playlists and favourites |

**Why it matters:** this inverts the natural work order. The instinct is "import everything, then hook up MA". The correct order is "hook up MA, prove it, *then* import" — because every re-tag after MA has indexed costs a refresh cycle, and a large re-tag after a large index costs a database reset.

**How to avoid:**
- Connect MA to a **small, already-final** subset first (P6 early spike).
- Do not point MA at the tree during active bulk import phases; connect, verify, disconnect, import, reconnect.
- Write stable MBIDs into files (`musicbrainz` plugin is already on). MA uses MBIDs and ISRCs to link items; stable identifiers let it re-match after a path change instead of creating a new entry.

**Phase to address:** **P6** early, then re-verified as the exit gate of **P5**, **P8**, **P9**.

---

### Pitfall 13: Tools that report success while writing nothing

**What goes wrong:**
`beets.md` documents the `rsync -a` case. The pattern is broader on this filesystem and the other instances are quieter:

1. **beets logs tag-write failures as warnings and continues.** `error writing /music/…: [Errno 1] Operation not permitted` does not abort the import. The file is copied, the *database* records the correct metadata, and the file on disk keeps its old tags. `beet ls` looks perfect. Jellyfin and MA — which read the files, not the database — show the old data. **The database and the filesystem silently disagree, and beets is the only one that looks right.**
2. **EPERM (errno 1) ≠ EACCES (errno 13).** Errno 13 is a plain permission denial and is loud. Errno 1 on this pool is the ACL case: the copy *succeeds*, then `chmod`/`chown`/`utime` on the new file fails. Documented upstream as OpenZFS #13408 — `chmod` reporting "operation not permitted" under `aclmode=restricted` with no visible ACLs. Knowing which errno you have tells you which problem you have.
3. **PUID/PGID does not grant ownership.** The LinuxServer beets image remaps the in-container user; it cannot make that user the owner of host files. linuxserver/docker-beets#68 reports imported files landing `root:root` despite correct PUID/PGID.
4. **The `permissions` plugin does not fix directories** (beets #2611 — file modes applied, directory modes not).
5. **`chmod -R 777` is ignored, without error, on some filesystems.** Verify with `ls -ln`, never with the exit code.

**How to avoid — a P1 write-probe, before any bulk run:**
```bash
zfs get acltype,aclmode,aclinherit tank/media tank/downloads
docker exec beets id
stat -c '%u %g %n' /mnt/tank/media/Music
# and the real test: import ONE album, then verify the FILE, not the DB
docker exec beets beet import -t /downloads/complete/nzb/music/<one-album>
ffprobe -v quiet -show_entries format_tags -of json '/mnt/tank/media/Music/…/01 ….flac'
stat -c '%u:%g %a' '/mnt/tank/media/Music/…/01 ….flac'
```
The verification that matters is `ffprobe` on the file, not `beet ls`. Make that the standing definition of "imported".

Do **not** blanket-apply `zfs set aclmode=discard tank/media` as the fix — it is the commonly cited remedy but it discards ACLs on every `chmod` thereafter, which may not be what other consumers of that dataset expect. Prefer making the container's uid the actual owner (`chown -R 568:545`, per the existing convention).

**Also: `move` across datasets is not a rename.** `/mnt/tank/downloads` and `/mnt/tank/media` are near-certainly separate ZFS datasets, so they have different `st_dev` and every "move" is copy-then-unlink. It needs transient space for both copies, it is slow, and an interruption mid-album leaves half the tracks in each location with a database that believes they are all in the destination.

**Phase to address:** **P1**.

---

### Pitfall 14: Abandonment — the failure mode with the highest prior probability

**What goes wrong:**
Three attempts, three abandonments, and the pattern is identical each time: **the machine was built and the labour was never scheduled.** Manual beets ran three imports on 18 Nov 2025 and stopped. soulbeet was configured and never deployed. wrtag was containerised, given a path format, and produced zero completed jobs in seven months. Every one of these is a *tooling* deliverable that reached "works" and never reached "used".

The arithmetic nobody does up front: ~7,451 files ÷ ~12 tracks ≈ **620 albums**. Buckets B and C — compilations and DJ services — are the majority of that, and they are exactly the content that cannot be automated. At a genuinely optimistic 45 s per timid confirmation, bucket B alone is multiple hours of undivided, uninterruptible, low-reward attention. That is not a task anyone completes in the gaps of a normal week, and it is not made shorter by a better tagger. MusicBrainz Picard's own documentation says the quiet part out loud: it *"is not intended to automatically organize a collection of thousands of random music files"* and *"is not built to be a mass single-track tag fixer."* The same is true of beets. **The tool is not the bottleneck; the confirm loop is.**

**Why it happens — four concrete predictors, all present in this project's history:**

| Predictor | Present here | Antidote |
|---|---|---|
| **Deliverable is a tool, not a visible outcome.** "Deploy wrtag" completes without a single album entering the library. | All three prior attempts | Every phase's exit criterion is *N albums visible in both consumers*, never *tool configured* |
| **Hardest content first, or all content at once.** Starting on the 45 GB *Now!* set or "the backlog" means the first session is the worst session and there is no early win. | The backlog is framed as one 97 GB blob | Bucket A first, explicitly because it is easy. PROJECT.md gets this right — protect it |
| **The inflow is never closed.** Working a backlog while Lidarr keeps adding to it is unwinnable, and it *feels* unwinnable, which is what actually stops people. | `audio.bash` currently logs `skip` on every job — inflow is untagged and growing | **P7 before the bulk backlog phases**, not after. Stop the bleeding first |
| **No definition of done.** "Tag the music library" has no end state, so there is no moment of success, so momentum has nothing to convert into. | Prior attempts had none | PROJECT.md's "done = pipeline fixed + bucket A imported" is correct. Do not let scope creep re-open it |

**How to avoid — concrete scoping and sequencing, not motivation:**

1. **Make the first phase produce a countable, visible result.** Not "beets configured" — *"12 albums, tagged, in Jellyfin and in Music Assistant."* Twelve is enough to prove every layer and small enough to finish in one evening.
2. **Close the inflow before opening the backlog.** P7 (one working ingest path) before P8/P9. This is the highest-leverage sequencing decision available and it inverts the intuitive order.
3. **Time-box, do not album-box.** A session is 30 minutes, then stop regardless of position. Album-count targets punish you for hitting a hard case, which is exactly when you most want to stop and least should feel bad about it.
4. **Define a "good enough" tier and hold it.** albumartist / album / title / track / year / MBID. Release-level disambiguation on every DJ compilation is the trap. Perfect is why this died three times.
5. **Keep a defer bucket that is a real, legitimate destination.** Anything that resists for 2 minutes goes to a `_review/` path (note: **not** underscore-prefixed if MA indexes it — use `review/`) and is revisited never or annually. Its existence is what stops a single bad album ending a session.
6. **Batch by cohesion, not by count.** One artist, or one DJ series, per session. The disambiguation decision repeats and gets faster; 50 random albums resets the decision every time.
7. **Explicitly declare buckets B and C out of the milestone.** PROJECT.md already does. The roadmap must not quietly convert "worth doing" into "in scope".
8. **Ship the retirement work (P2) even if nothing else lands.** If this attempt also stalls, the estate is still strictly better than it started: one tagger instead of four, one database instead of four, no idle container holding a rw mount on the library. That is the insurance policy against attempt five inheriting attempt four's wreckage — which is the actual compounding cost of the previous three failures.

**Warning signs — check these at every phase transition:**
- A phase completed and the album count in Jellyfin did not change.
- Two consecutive sessions spent on configuration.
- The word "just" appearing before a scope addition ("just also do the *Now!* set while we're here").
- Any session that ran past 45 minutes because a single album would not resolve.
- More than ~10 days since the last import ran. This is the leading indicator; all three prior deaths look identical at day 10.

**Phase to address:** Roadmap structure itself. Specifically: **P5 must be small and early**, **P7 must precede P8/P9**, and **P2 must be independently shippable**.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|---|---|---|---|
| `import.move: yes` on a first pass | No transient duplication; source auto-cleans | No undo. Combined with `scrub`, wrong matches are unrecoverable | **Never** until bucket A has been proven end-to-end. `tank` has 9 T |
| `quiet_fallback: asis` to stop the `skip` logs | Ingest "works" again immediately | Thousands of files enter the library with filename-derived tags, moved out of source | **Never** with `move` enabled. Use `-A -C -M` if as-is is genuinely wanted |
| Leaving retired taggers defined but stopped | Nothing to do | A stopped container with a rw mount on the library is a loaded gun; this estate has already been bitten by unnoticed `created`-state containers | Only if the library mount is removed from the definition at the same time |
| Point Music Assistant at the tree now, sort it later | Proves the mount early | Every subsequent re-tag leaves stale MA entries a rescan will not clear; large re-tag ⇒ database reset | Acceptable **only** against a small final subset |
| `zfs set aclmode=discard` to make `chown`/`chmod` work | Unblocks permissions in one command | Discards ACLs on every future `chmod`; affects every other consumer of the dataset | Only if nothing else relies on NFSv4 ACLs on `tank/media` — verify first |
| Skipping the tag snapshot before DJ processing | Saves 10 minutes | `scrub` + `-A` destroys the only evidence needed to repair the field mapping | Never |
| Adding `*.jpg`/`*.nfo` to beets `clutter` | Stops orphan sidecar folders | beets deletes DJ cover scans and Jellyfin artwork during directory pruning | Only after DJ scans are archived elsewhere |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|---|---|---|
| **Jellyfin** | Leaving `SaveLocalMetadata` on during a re-tagging project | Turn it off for the duration. `.nfo` outranks embedded tags and Jellyfin will not refresh from re-written tags |
| **Jellyfin** | Letting scheduled scans run during bulk moves | Pause scans; back up the Jellyfin DB before the first batch. Moves duplicate items and empty playlists |
| **Music Assistant** | Assuming an HA `/media` mount will be visible | Docs say a folder cannot be mounted from HA into `/media`. Use the **Filesystem (remote share)** provider (prefer NFS over SMB — SMB skips special characters). Verify with 3 albums first |
| **Music Assistant** | Relying on rescan to clear stale entries | It does not. Escalate: `REFRESH ITEM` → per-item removal → remove provider **and wait for cleanup before any restart** → database reset |
| **Music Assistant** | Omitting `albumartist` on DJ imports | MA hard-requires Album Artist; without it everything collapses into Various Artists or folder names |
| **MusicBrainz** | Enabling `chroma` to fix compilation matching | It measurably degrades compilation matching (beets #360). Use `musicbrainz.extra_tags` and manual release IDs instead |
| **MusicBrainz** | `countries: ['UK']` | MusicBrainz uses `GB`. The values are regexes: `['GB|UK', 'US']` |
| **sabnzbd `audio.bash`** | Treating the `skip` result as a bug to configure away | It is the correct output for unmatched content. Fix the routing, not the threshold |
| **Renovate** | Trusting the wrtag `<0.30.0` pin as a settled decision | The path format in `wrtag.yaml` is already written in v0.30+ syntax. Verify the container actually works before spiking it |
| **ZFS / Docker** | Assuming PUID/PGID grants ownership | It remaps the in-container uid only. `chown -R 568:545` on the host and verify with `ls -ln` |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|---|---|---|---|
| Pointing one import at the `Now! 1–115` folder | beets groups a directory as one album; hangs, or produces one 2,000-track "album" | `beet import --pretend` first; split per volume before importing | Immediately — 45 GB, 115 releases |
| `move` across ZFS datasets | Slow "moves"; transient double space; half-imported albums after an interruption | Expect copy+unlink. Consider `import.reflink: auto` (OpenZFS block cloning, 2.2+, same-pool only) to make copies near-free | Any cross-dataset import |
| Interactive confirmation across ~620 albums | Sessions get longer, then stop happening | Time-box; batch by cohesion; defer bucket | ~50 albums in — the historical death point |
| MusicBrainz rate limiting on a large unattended run | Import slows to a crawl; intermittent match failures that look like content problems | 1 req/s is the ceiling. Run bulk imports overnight; do not interpret rate-limit failures as bad content | Several hundred lookups |
| Jellyfin scan racing a bulk import | Duplicate items, ghost albums, emptied playlists | Pause scheduled scans; scan once, after | Any batch larger than a few albums |
| Music Assistant syncing a tree still being written | Partial library; entries that never clear | Connect MA only between phases, never during | Any bulk import |

---

## Security Mistakes

Low-severity domain, but non-zero:

| Mistake | Risk | Prevention |
|---|---|---|
| Exposing the tagger UI without auth | beets/wrtag web UIs have filesystem write access to the whole library | Both are already behind `chain-authelia@file` — keep it that way if either is retired-but-kept |
| Music Assistant remote share reachable off-LAN | MA adds no encryption or access control of its own; the share is as exposed as the network makes it | Keep NFS/SMB LAN-only; do not route it through Tailscale exit nodes casually |
| `AcoustID` submission enabled by default thinking | `beet submit` uploads fingerprints and metadata from your collection | Only relevant if `chroma` is enabled — which Pitfall 8 argues against anyway |
| Leaving a retired tagger's container rw-mounted on `/mnt/tank/media/Music` | Any compromise or accidental start writes to the library | Remove the mount, not just the `restart:` policy |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---|---|---|
| DJ content landing in `Compilations/` | Genuine various-artist albums become unfindable among 85 Mastermix issues | Dedicated path (`paths: albumtype:dj:`), as PROJECT.md already decides |
| Trusting `beet ls` as proof of success | Library "looks tagged" while Jellyfin and MA show old data | Verify with `ffprobe` on the file, in both consumers |
| Jellyfin and MA disagreeing about what exists | Silent, undebuggable — a track plays on the TV and not on the speakers | Make dual-consumer album counts a standing check, not an end-of-project one |
| Underscore-prefixed staging directories inside the library tree | MA silently ignores them; Jellyfin does not — the two consumers diverge by design | Never prefix a library directory with `_` |
| Genre replaced wholesale by Last.fm tags | Browsing by genre becomes useless; "seen live" as a genre | `lastgenre: auto: no`; run it deliberately on bucket A only |

---

## "Looks Done But Isn't" Checklist

- [ ] **Import succeeded:** verify the **file** with `ffprobe`, not `beet ls`. beets logs tag-write EPERM as a warning and continues, leaving the DB right and the file wrong.
- [ ] **File landed:** verify with `stat -c '%u:%g %a'` that ownership is `568:545`, not `root:root`. Exit code 0 does not mean the write happened on this pool.
- [ ] **Album is correct:** verify **track count and total duration** against the matched release, not the title. Wrong-release matches are complete and plausible.
- [ ] **Visible in Jellyfin:** verify the *metadata shown* is the new metadata, not the old — a stale `.nfo` outranks the re-written tags.
- [ ] **Visible in Music Assistant:** verify the album count, and check MA's sync log for skipped-file warnings (non-UTF-8 names are skipped silently-ish).
- [ ] **No collisions:** `find … -regex '.*\.[0-9]+\.(mp3|flac|m4a)$'` returns nothing.
- [ ] **No orphans:** no directory under `/media/Music` contains only `.nfo`/`.jpg` and no audio.
- [ ] **Tagger retired:** the container definition is gone *and* the `/mnt/tank/media/Music` mount is gone — not just `restart: "no"`.
- [ ] **Ingest path fixed:** a real new download completed end-to-end without a `skip`, with a persistent database and a readable log.
- [ ] **`albumartist` is set** on every imported album — MA requires it; beets does not enforce it on `-A` imports.
- [ ] **DJ scans archived** to a path no tagger can write to, before any DJ processing.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---|---|---|
| Wrong match, `copy` mode | **LOW** | `beet remove -a <query>` (no `-d`) → delete copies in destination → re-import from untouched source |
| Wrong match, `move` mode | **HIGH** | No undo. Restore the pre-run `library.db` backup, `beet move` to restore paths. Tags are not recovered. If `scrub` ran, original tags are gone permanently |
| `scrub` destroyed DJ tags | **HIGH → LOW with prevention** | Only recoverable from the pre-run `ffprobe` JSON snapshot. Without it: re-source from cover scans, Internet Archive, or the DJ service directly |
| Bad path format applied at scale | **MEDIUM** | beets: fix `paths:`, then `beet move` (use `-p` to dry-run first). wrtag: `wrtag move`/`sync`, but `sync` is unsafe on this shared tree |
| Two databases diverged over one tree | **HIGH** | No merge tool exists. Rebuild one database from the tree with `beet import -A -C -M` (catalogue in place, no movement), accepting existing tag quality |
| Jellyfin duplicated/emptied after a move | **MEDIUM** | Restore the Jellyfin DB backup; otherwise rewrite paths in the DB plus the XML files under `data/playlists/` and `data/collections/`, then rescan. Delete-and-rescan loses play counts and playlists |
| Stale Jellyfin metadata after re-tag | **LOW** | Delete the `.nfo` and `config/metadata/artists/<name>`, then rescan. Prevention: `SaveLocalMetadata: false` |
| Music Assistant stale entries | **MEDIUM** | `REFRESH ITEM` → per-item removal → remove provider and **wait for cleanup before restarting MA** (restarting early makes recovery impossible) → Reset Library Database |
| EPERM writes on `tank` | **LOW** | `zfs get acltype,aclmode,aclinherit`; `chown -R 568:545`; re-run. Verify with `ls -ln`, not exit codes |
| Project stalled at 20% | **Structural** | Ship P2 (retirement) independently so attempt five inherits a clean estate rather than a fifth half-pipeline |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---|---|---|
| 1. `scrub` destroys tags | P1 | `scrub: auto: no` in config; DJ tag snapshot JSON exists on disk |
| 2. `lastgenre`/`embedart` overwrites | P1 | `auto: no` on both; genre distribution across a test batch is varied |
| 3. `-q` auto-accept / `quiet_fallback` trap | P1, P7 | `quiet_fallback` unset or `skip`; ingest routes low-confidence to review, not to library |
| 4. Stateless `library.blb` | P2, P7 | Ingest DB persists across runs; `.1` collision search returns nothing |
| 5. Four databases, one tree | **P2 (blocks P5)** | Only one tagger container definition exists; others have no library mount |
| 6. `wrtag sync` / dropped scans | P2, P9 | wrtag retired or rooted at a fresh path; DJ scans archived to a read-only-for-taggers location |
| 7. wrtag path-format pin | P3 | `docker logs wrtag` clean, or wrtag disqualified in one command |
| 8. `preferred.countries` is only a tiebreaker | P1, P8 | `extra_tags` configured; `countries: ['GB\|UK','US']`; no US-country match on *Now!* volumes below 1998 |
| 9. Undetected wrong matches | P1, P5 | Detection sweep is a documented, repeated step — not a one-off |
| 10. Jellyfin `.nfo` authority + move damage | P1, P5 | `SaveLocalMetadata: false`; scans paused; Jellyfin DB backed up; no sidecar-only directories |
| 11. MA cannot see an HA `/media` mount | **P6, run early** | 3 albums visible in MA via the chosen provider, before P5 scales |
| 12. MA stale entries | P6, gate on P5/P8/P9 | MA connected only between phases; album counts match Jellyfin |
| 13. Silent write failures | P1 | `ffprobe` + `stat` on a real imported file is the definition of "imported" |
| 14. Abandonment | **Roadmap structure** | P5 small and early; P7 before P8/P9; P2 independently shippable; import cadence never exceeds 10 days |

---

## Sources

**Official documentation (HIGH confidence):**
- beets scrub plugin — strip-then-write behaviour, `auto` default: https://beets.readthedocs.io/en/stable/plugins/scrub.html
- beets configuration reference — `match.preferred`, `quiet_fallback`, `duplicate_action`, `clutter`, `import.move`, `reflink`: https://beets.readthedocs.io/en/stable/reference/config.html
- beets CLI reference — `--pretend`, `-t`, `-A`, `-C`, `-M`, `-q`, `beet move -p`, incremental flags: https://beets.readthedocs.io/en/stable/reference/cli.html
- beets MusicBrainz plugin — `extra_tags`: https://beets.readthedocs.io/en/stable/plugins/musicbrainz.html
- beets chroma plugin: https://beets.readthedocs.io/en/stable/plugins/chroma.html
- beets FAQ — no undo; moving a library: https://beets.readthedocs.io/en/stable/faq.html
- beets source, `util.unique_path` / `Item.move_file` — verified no-clobber `.1` suffix behaviour: https://github.com/beetbox/beets/blob/master/beets/util/__init__.py
- wrtag README — `sync` destructive warning, `-dry-run`, `-yes`, `-keep-file`, source cleanup: https://github.com/sentriz/wrtag
- wrtag v0.30.0 release notes — path-format breaking change table: https://github.com/sentriz/wrtag/releases
- Jellyfin local `.nfo` metadata — priority of local metadata: https://jellyfin.org/docs/general/server/metadata/nfo/
- Jellyfin music library docs: https://jellyfin.org/docs/general/server/media/music/
- Music Assistant File System source — HAOS `/media` restriction, remote-share providers, Album Artist requirement, underscore/UTF-8/emoji skipping: https://www.music-assistant.io/music-providers/filesystem/
- MusicBrainz Picard introduction — explicit scope disclaimer on mass tagging: https://picard-docs.musicbrainz.org/en/latest/about_picard/introduction.html

**Issue trackers and community (MEDIUM confidence):**
- beets #360 — chroma degrading compilation match distance: https://github.com/beetbox/beets/issues/360
- beets #2611 — permissions plugin does not affect directory permissions: https://github.com/beetbox/beets/issues/2611
- linuxserver/docker-beets #68 — imported files owned root:root despite PUID/PGID: https://github.com/linuxserver/docker-beets/issues/68
- OpenZFS #13408 — chmod EPERM under `aclmode=restricted`: https://github.com/openzfs/zfs/issues/13408
- Jellyfin #4728, #12297, #11625, #14589 — move/scan playlist and duplicate damage: https://github.com/jellyfin/jellyfin/issues/4728
- Jellyfin #13655, #13350, #16356 — NFO precedence and refusal to refresh from re-tagged files: https://github.com/jellyfin/jellyfin/issues/13655
- Jellyfin feature request #3121 — no orphan file cleanup: https://features.jellyfin.org/posts/3121/orphan-file-scanner-and-cleaner
- Music Assistant support #4877 — deleted media never removed from library: https://github.com/music-assistant/support/issues/4877
- Music Assistant support #4846 — folder rename leaves stale entries after forced sync: https://github.com/music-assistant/support/issues/4846
- Music Assistant discussion #452 — mount-timing race on HA `/media` SMB mounts: https://github.com/orgs/music-assistant/discussions/452

**This estate (HIGH confidence — verified in-repo 2026-08-17):**
- `stacks/selfhosted/arrs/soulbeet/beets_config.yaml` — `scrub`, `lastgenre auto: yes`, `embedart auto: yes`, `import.move: yes`, `strong_rec_thresh: 0.04`
- `stacks/selfhosted/music/wrtag.yaml` — v0.20.0 pin with a v0.30+ path-format template; library mounted at `/mnt/tank/media/Music`
- `stacks/selfhosted/arrs/beets/beets.yaml` — `/mnt/tank/media` mounted rw on a profile-gated container
- `stacks/selfhosted/arrs/beets.md`, `.planning/PROJECT.md` — prior art, three-abandonment history

---
*Pitfalls research for: self-hosted music library consolidation (Deer Crest estate)*
*Researched: 2026-08-17*
