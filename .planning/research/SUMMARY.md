# Project Research Summary

**Project:** Music Library Consolidation (Deer Crest selfhost estate)
**Domain:** Self-hosted music tagging pipeline — acquire → tag → organise → serve two consumers
**Researched:** 2026-08-17
**Confidence:** MEDIUM-HIGH

---

## Executive Summary

This is not a tagging problem. It is a **write-ownership problem wearing a tagging problem's
clothes.** Four tagging entry points were built over three years and every one of them was
pointed at `/mnt/tank/media/Music` with its own private database. Research found a fifth writer
nobody had counted: **Lidarr's root folder is `/media/Music` with `renameTracks: True`**, so
Lidarr has been actively renaming files inside the shared tree the whole time. The reason this
project was rebuilt and abandoned three times is that each rebuild began by trying to re-derive
state from a tree that no single tool could account for. The governing rule for everything below
is therefore: **the library tree is an output, not a workspace. Exactly one process writes it.
Everything else reads it.** Any design in which two processes can rename, move or re-tag the same
path reintroduces the original bug regardless of which tools are chosen.

On tools, the research converged hard and independently: **use beets 2.13.1, retire wrtag.** Four
separate lines of evidence arrive at the same answer. (1) wrtag is MusicBrainz-only by design and
has no Discogs support — and Discogs is where this collection's DJ releases actually live
(verified: `Mastermix Issue 430`, `Issue 433`, `DMC Commercial Collection 350` all resolve on
Discogs and return nothing on MusicBrainz). (2) wrtag holds a live read-write mount on the library
today, `restart: unless-stopped`, idle since January. (3) `wrtag move` deletes source folders and
does not carry over non-music files without an explicit `-keep-file` rule — which would silently
destroy the **54 DJ cover scans**, the single most valuable irreplaceable asset in the backlog.
(4) The version pin is inverted: `wrtag.yaml` runs a v0.30+ path-format template on a v0.20.0
binary that hard-sets `Track.Position = -1` and has no `.Media` field at all, so it has never been
able to render a path. That last point is now confirmed empirically — **no `Compilations/`
directory exists on the library; wrtag has written nothing, ever.** The spike should still run,
but its job is to produce a number (Discogs match rate on normalised DJ folders), not to relitigate
the direction.

The dominant risk is not technical. It is **abandonment**, and it has a 3-for-3 track record here.
The arithmetic nobody has done: ~7,451 files ÷ ~12 tracks ≈ **620 albums**, of which the majority
are compilations and DJ releases — exactly the content that cannot be automated. A better tagger
does not shorten the confirm loop. Every prior attempt shipped a *tool* and never shipped an
*album*. The structural antidotes are: every phase exits on "N albums verified with `ffprobe` AND
visible in both Jellyfin AND Music Assistant" — never on "tool configured"; the retirement work
must be independently shippable so a fourth stall still leaves the estate strictly better than it
started; and the inflow must be closed before the backlog is opened. On the last point, research
found the actual cause of the ingest failure: **`/config/scripts/beets-config.yaml` declares
`plugins: embedart` and nothing else.** Since beets 2.4.0 MusicBrainz is a plugin, so that config
has no metadata source at all — every album must skip regardless of its content. The logged `skip`
outcomes of 1 Aug and 8 Aug are not a threshold problem and not a content problem. They are a
config with no tagger in it.

---

## Key Findings

### Recommended Stack

**beets 2.13.1 as the single tagger, with `discogs` as the second metadata source.** The decision
is not "beets is better software" — wrtag is faster, has a better import queue, and `wrtag sync`
is a capability beets does not match. The decision is that this project has two dominant problems
and wrtag can address neither: ~110 of ~170 backlog folders are DJ-service releases outside
MusicBrainz, and the DJ content is *already tagged, just wrongly mapped*, which needs a repair
tool (`-A`, `edit`, `modify`, `zero`) not a fetch tool. beets also already holds the estate's
library state and is already documented in `beets.md`; consolidating onto it removes three entry
points, consolidating onto wrtag would mean rebuilding all of them.

**Core technologies:**

- **beets 2.13.1** (`lscr.io/linuxserver/beets:2.13.1`, never `:latest`/`:nightly`) — sole tagger,
  sole writer of the library tree, sole holder of import state.
- **beets `musicbrainz` plugin** — must be listed **explicitly**. Since 2.4.0 a customised
  `plugins:` list that omits it silently disables autotagging. This defect is present in *two*
  configs in this repo and is the confirmed cause of the ingest skips.
- **beets `discogs` plugin** (`pip install "beets[discogs]"`, `user_token` — the OAuth flow is
  unworkable in a container) — the only route to Mastermix/DMC/Music Factory metadata.
- **beets `importsource`** — records `source_path` per item, which is what makes a 7,451-file
  import resumable after an interruption. Enable from day one.
- **mutagen 1.48.1** — the DJ field-remap script. Per-folder classification, then a reviewable CSV
  diff, then apply. It is the library beets uses underneath, so tags written are read back
  identically. `kid3-cli 3.10.1` is plan B; Mp3tag on the Mac is for *prototyping* rules on 20
  files, never the bulk run.
- **NFSv4, read-only, host-restricted** from the Proxmox host (not from LXC 100 — it is
  unprivileged and nfsd is privileged-only). Chosen over SMB because ZFS is case-sensitive and
  MA's docs state emoji/special characters are unsupported on CIFS shares.
- **A cloud VLM (Gemini 3 Flash / Claude Opus 4.6)** for the 54 cover scans. 54 images once; the
  self-host break-even is ~50k–100k pages/month, and the host iGPU has a documented
  `amdgpu_hmm_invalidate_gfx` oops history. Cross-check every extracted tracklist against Discogs —
  the failure mode is hallucination, not OCR noise.

Full detail: [STACK.md](STACK.md).

### Expected Features

**Must have (table stakes — the pipeline is broken without these):**

- **One owned ingest path, exactly one** — and one persistent `library.db`. The current
  `audio.bash` beets `rm`s its own database every run, which silently kills incremental import,
  duplicate detection, and any audit trail. This single fix unlocks four other features.
- **`copy`, not `move`, on every first pass** — verified: **there is no `beet undo`**. The current
  `soulbeet` config sets `move: yes`. A bad bulk run over 97 GB would consume its own source.
  `tank` has 9 T free; take the duplication.
- **Explicit disposition for every item** — import log as a *worklist* (`-l LOGFILE`,
  `--from-logfile`), plus a quarantine path. A silent `skip` is what killed the last attempt.
- **Correct `ALBUMARTIST` on every track** — Music Assistant treats it as *mandatory*; Jellyfin
  groups on it. This is the one tag both consumers depend on most.
- **Folder name == the `ALBUMARTIST` tag, exactly, including case** — Jellyfin #12845 and #11190:
  a capitalisation-only mismatch renders a duplicate artist page. This one rule produces
  `Various Artists/` over `Compilations/`, and kills the `DJ-Mixes/` pseudo-artist idea.
- **`;` as the multi-artist delimiter** — free convergence: Jellyfin mis-parses `,`; MA supports
  `;` and nothing else.
- **Staging outside `/media/Music`** — Jellyfin's `SaveLocalMetadata: true` contaminates any folder
  under the library root within minutes, and `.ignore` is not a safe workaround (semantics changed
  in 10.11.x; jellyfin#14502 has empty `.ignore` folders scanned anyway).
- **Bucket D junk gate before anything else** — `_FAILED_`, `_UNPACK_`, stray `.rar`, and a
  **Harry Potter BluRay rip currently misfiled in `dj-mixes`**.
- **Verification against both consumers, not against disk.**

**Should have (differentiators):**

- **Preview-and-review UI (beets-flask)** — directly attacks the abandonment mode. Automation
  produces a decision, the human ratifies it, and the decision is *persisted* so ratification can
  happen later. Its inbox model (one `library.db`, N policy-carrying folders) is exactly the
  architecture recommended below.
- **`incremental` + `incremental_skip_later: yes`** — the sharpest trap in the feature set. The
  default (`no`) records *skipped* directories too, so a quiet first pass permanently marks every
  hard album "done" and it is never offered again. The 97 GB becomes invisible rather than imported.
- **Separate library root for DJ content** (`/mnt/tank/media/DJ`, its own Jellyfin library and its
  own MA provider) — not a `DJ-Mixes/` pseudo-artist folder inside the music root.
- **Duplicate reconciliation with tiebreak + quarantine** — all 85 `dj-mixes` folder names collide
  with `unsorted`, and sizes differ in *both* directions, so neither side is authoritative.
  `-m /quarantine`, never `--delete`.
- **`unimported` as a standing leak detector**; **decoupled backfill passes** for art/ReplayGain/genre.

**Defer (post-milestone):**

- **DJ field-mapping normalisation** — HIGH operator value, deliberately P3. It is the most
  interesting problem here, which is precisely why it is the most likely to consume the project
  and cause the fourth abandonment.
- **Cover-scan extraction** — 32% coverage, high effort.
- **`badfiles` integrity gate**, **`mbsubmit` contributions** (capped and opt-in — MusicBrainz
  *deletes* poorly-added releases, and DJ-pool repacks are exactly the category that gets
  voted down).

Full detail: [FEATURES.md](FEATURES.md).

### Architecture Approach

A **watch-folder/inbox service with per-inbox policy and a manual escape hatch inside the same
process.** Routing happens at the *input* — moving a folder into `02-review/` *is* the decision,
inspectable with `ls`, revertible with `mv`, surviving a container restart with no database. All
inboxes converge on one import engine and one state store; destination differences (DJ vs
compilation vs artist album) are expressed as **path-format rules, never as a second tagger**. The
moment "manual" means "a second container with its own database", the original bug is back.

Tagging must not live in SABnzbd's post-processing hook: SAB post-processing is **serial with no
timeout**, so one wedged release stalls every job behind it, failures surface as "the queue looks
slow", and per-job state means the tagger never sees the library. Thin hook (one `mv` into an
inbox, then exit), thick worker.

**Major components:**

1. **Acquisition** (Lidarr + SABnzbd) — decides *what* to fetch and fetches it. Owns no filenames,
   no layout, no tags. Lidarr's root folder moves off `/media/Music` and `renameTracks` goes off.
2. **Staging tree** (`tank/downloads/.../_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}`)
   — holds undecided content and encodes the routing decision as a directory. Filesystem-as-queue:
   the unit of work is a release directory, and every transition is an atomic same-dataset `rename(2)`.
3. **Tagger** (one beets instance, one `library.db`) — sole writer of the library, sole holder of
   import state.
4. **Library dataset** (`tank/media/Music`) — inert, canonical, read-only to everything else.
5. **Consumers** — Jellyfin over a `:ro` bind mount with its metadata savers **off**; Music
   Assistant over a `ro` NFSv4 export from the Proxmox host. Read-only is enforced at the
   mount/export layer, not by configuration politeness.

Two ZFS facts shape the data flow, both now confirmed against `infra/lxc-selfhost.tf`:
`/mnt/tank/downloads` and `/mnt/tank/media/Music` are **separate datasets**, so a library "move" is
copy-then-unlink (interruptible, can leave a truncated file, needs transient double space) and
`cp --reflink` fails `EXDEV` across datasets even within one pool. Moves *within* `tank/downloads`
are atomic — which is exactly why the routing directories all live there.

Every batch runs inside a **snapshot fence**: `zfs snapshot tank/media/Music@pre-import-…` plus a
copy of `library.db`, taken together and rolled back together. Rolling back only the tree leaves
the tagger's `incremental` state claiming those releases are done.

Full detail: [ARCHITECTURE.md](ARCHITECTURE.md).

### Critical Pitfalls

1. **`scrub` strips the only surviving metadata before beets writes its own.** `scrub.auto`
   defaults to **yes**, and the `soulbeet` config enables the plugin with no `scrub:` section.
   Combined with `import.write: yes` it removes the entire tag block and writes back only fields
   beets models — destroying BPM, issue numbers, mix/version, key, and clean/dirty flags. On
   bucket A that is cosmetic. On bucket C it is catastrophic and irreversible, because the file's
   own tags are the *only* source of truth and are also the evidence needed to repair the broken
   field mapping. → `scrub: auto: no` before any import runs, plus a one-command `ffprobe` JSON tag
   dump of all 794 `dj-mixes` files as the recovery artefact.

2. **N databases over one destination tree.** Not two, as `beets.md` says — four state stores plus
   Lidarr. `beet update` silently *prunes* items another tool moved, taking the `mb_albumid` with
   them. `%aunique{}` cannot disambiguate across databases, so two different releases with the same
   `$albumartist/$album` land on one path and beets appends `.1`, producing a merged pseudo-album.
   There is no merge tool; recovery is re-importing one side. → Retirement is a correctness
   prerequisite, not cleanup. Remove the *mount*, not just the `restart:` policy — a stopped
   container with a rw mount on the library is a loaded gun, and this estate has already lost six
   weeks to unnoticed `created`-state containers.

3. **`quiet_fallback: asis` is the trap fix for the ingest skips.** The symptom looks like a config
   problem and there is a one-line config change that makes it disappear — which would import 7,451
   untagged files with filename-derived garbage, moved out of the source, in one unattended run.
   This is the single most plausible way this project destroys itself while trying to unblock
   itself. → The real fix is routing low-confidence content to a review queue. If as-is import is
   genuinely wanted, use `-A -C -M` so only the database changes. (And on this estate the skips have
   a *different*, now-known cause — see the corrections section.)

4. **Music Assistant never purges stale entries, and this inverts the natural work order.** Issues
   #4877 and #4846: re-tagging or moving files under an indexed tree leaves stale entries that a
   rescan does not remove, and the escalation path ends at a full library database reset. The
   instinct is "import everything, then hook up MA". The correct order is **hook up MA, prove it on
   three albums, then import** — and disconnect MA during bulk phases. There is also a one-shot
   recovery window: if MA is restarted before provider-removal cleanup completes, recovery is no
   longer possible.

5. **Tools that report success while writing nothing.** `rsync -a` on `tank` is already documented,
   but the quieter instances matter more: beets logs a tag-write `EPERM` as a *warning* and
   continues, so the file is copied, the database records the correct metadata, and the file on disk
   keeps its old tags. `beet ls` looks perfect while both consumers show stale data. Errno 1
   (ACL case, OpenZFS #13408) is not errno 13. PUID/PGID does not grant ownership
   (linuxserver/docker-beets#68 has files landing `root:root`). → **The definition of "imported" is
   `ffprobe` on the file plus `stat` on its ownership — never `beet ls`.**

6. **Abandonment.** Highest prior probability of any risk here, 3-for-3. Predictors all present:
   the deliverable is a tool rather than a visible outcome; the backlog is framed as one 97 GB blob;
   the inflow is never closed; there is no definition of done. Leading indicator: **more than ~10
   days since the last import ran.** All three prior deaths look identical at day 10.

Full detail: [PITFALLS.md](PITFALLS.md).

---

## Resolved Conflicts Between Research Streams

The four researchers disagreed in three places. Resolved or explicitly flagged, not averaged.

### 1. MusicBrainz DJ coverage — RESOLVED, both were right about different things

FEATURES reported 18 `Mastermix Issue` releases, 19 `DMC Commercial Collection`, 9
`Music Factory Mastermix` in MusicBrainz. STACK reported that coverage stops around 2016 and that
surviving entries are **stubs**. These are the same finding at different resolutions.

**The reconciled statement:** MusicBrainz carries roughly 46 release entries across these labels,
clustered 2011–2016. `Mastermix Crate` and `Mastermix Toolkit` return genuinely zero. **This
backlog's own issues — 430, 433, 441, 444 — return zero.** Where an issue number *does* hit, the
entry is frequently a 5–10 track stub against a real 15–20 track release, which is **more dangerous
than absence**, because an autotagger will match an 18-track folder against a 7-track entry and
produce a confident, complete, plausible, wrong result with no error state.

**What this means operationally:**
- The blanket claim in PROJECT.md and `beets.md` ("not in MusicBrainz, no autotagger will ever
  match them") is **wrong as written** but **right in its conclusion**. Correct the wording, keep
  the behaviour.
- Run a cheap **coverage probe** over the 85 folder names rather than assuming. One scripted pass,
  ~10 minutes, converts an assumption into a fact — and any release it *does* find gives you a
  known-correct target field mapping to normalise the other 80 toward.
- `beet import -t` (timid) is **mandatory** on every bucket C folder, and the check that matters is
  **track count and total duration**, not the title list. Eyes slide over titles; two numbers do not.
- Discogs, not MusicBrainz, is the source for this content — verified live on issues 430, 433 and
  DMC 350.

### 2. HAOS mount route — UNRESOLVED, flagged, with a defined empirical test

| Source | Claim |
|---|---|
| PROJECT.md | Assumes the mount is added through HA's own storage configuration |
| STACK (HIGH on mechanism) | HA → Settings → System → Storage, usage **Media** → `/media/<name>`; the MA add-on declares `map: [media:rw]`, so anything HAOS mounts under `/media` is directly visible. Read from `supervisor/mounts/mount.py` and the add-on's `config.yaml` |
| ARCHITECTURE | Same recommendation; HA-managed mount preferred because Supervisor manages its lifecycle across restarts and add-on reinstalls |
| PITFALLS | MA's filesystem-provider docs say **verbatim**: *"For Home Assistant OS only the `/media` folder can be accessed. […] It is not possible to mount a folder from Home Assistant into the `/media` path."* Plus a mount-timing race (MA discussion #452) where MA can begin syncing before the share is mounted, producing a partial library or one that empties after a NUC reboot |

**Do not paper over this.** It is a stated phase-completion gate in PROJECT.md, which means getting
it wrong is discovered *at the end of a phase, after the import work is done* — precisely the shape
of failure that produces abandonment.

**Critical structural observation that de-risks it:** both candidate routes need the same NFSv4
export from the Proxmox host. The export is a Terraform change in `infra/`, it is on the critical
path either way, and it depends on nothing else. **Start it immediately, in parallel, and let the
test discriminate the route afterwards.**

**The empirical test that settles it (≤1 hour, 3 albums, before anything scales):**

1. On `atlantis` (172.16.1.158), export a **throwaway** directory holding 3 already-correct albums
   copied out of `/mnt/tank/media/Music`. Do **not** export the real library for this test.
2. HA → Settings → System → Storage → *Add network storage*: protocol NFS, server **`172.16.1.158`
   as an IP, never a hostname** (HAOS has no guaranteed resolver; a DNS failure presents as a
   silently dead mount), usage type **Media**, name `music-test`.
3. Confirm HA reports it connected and the Media browser lists files. If this fails, the HAOS route
   is dead and PITFALLS was right.
4. In the MA add-on, add a **Filesystem (local disk)** provider at `/media/music-test`. Trigger sync.
5. **PASS** = all 3 albums appear in MA under the correct album artist within one sync cycle.
   **FAIL** = the provider errors, the path is not found, or the sync completes empty.
6. On FAIL, immediately test **route B**: MA's own **Filesystem (remote share)** provider, NFS,
   same server and export, with no HA-side mount at all. Identical pass criterion.
7. Whichever route passes, **reboot the NUC once and re-check that the library is still populated.**
   This is the mount-timing race and it does not show up on the first sync.
8. Record the answer as a Key Decision in PROJECT.md, and correct PROJECT.md's assertion either way.

Two constraints apply regardless of which route wins, and both should be built in from the start:
HAOS gives you **no NFS mount options** (`NFSMount.options` is hardcoded to `softerr,timeo=100,
retrans=2` plus `ro` — there is no `uid=`, no `gid=`, no `vers=`), so **all identity mapping must be
solved server-side in `/etc/exports`**; and MA hard-requires `albumartist`, so the phase gate is
"MA shows the album under the right artist", not "files are visible".

### 3. Phase-1 content — RESOLVED in favour of a reduced safety harness first

| Source | Wants first |
|---|---|
| PITFALLS | Safety harness — `scrub` off, `lastgenre`/`embedart` off, Jellyfin savers off, snapshots, tag dumps |
| ARCHITECTURE | Tagger spike (step 0) — "cannot retire taggers before knowing which one survives" |
| STACK | Normalisation must precede Discogs matching |

**Defensible ordering: harness first, then spike, then retirement.** The reasoning:

- **Every harness item is tagger-independent.** `scrub: auto: no`, `lastgenre: auto: no`,
  `embedart: auto: no`, Jellyfin `SaveLocalMetadata` off, scheduled scans paused, Jellyfin DB
  backed up, ZFS snapshot + `library.db` copies, the `ffprobe` tag dump of `dj-mixes`, and the
  `rsync` copy of the 54 cover scans to a tagger-unwritable path. None of these depend on which
  tool wins, and several protect assets that cannot be recreated if lost.
- **ARCHITECTURE's objection is about *retirement*, not *neutralisation*, and it is correct about
  retirement only.** Stopping wrtag and removing its `/mnt/tank/media/Music:rw` mount is not a
  tagger decision — it is removing a live second writer. And it is now free: **verified this session
  that no `Compilations/` directory exists, so wrtag has never written anything to the library.**
  There is nothing to preserve and nothing to decide. The same applies to Lidarr's `renameTracks`.
- **STACK's constraint is real but it is a *within-bucket-C* ordering, not a phase-1 concern — with
  one exception that bites the spike.** beets builds its Discogs query from the existing `artist` +
  `album` tags. With `album="VA"` that query is useless. **A spike that measures Discogs coverage
  against raw, un-normalised DJ tags will under-report and could wrongly disqualify beets.** So the
  spike must include a ~20-folder normalisation pre-step, or its bucket-C number is invalid.
  Sequence within bucket C: `strip BPM → repair field mapping → set albumtype=dj → beet import -t
  with discogs → review`.

---

## Implications for Roadmap

Nine suggested phases. Phases 1–9 constitute the milestone as PROJECT.md scopes it (pipeline fixed
+ bucket A proven). Buckets B and C are listed after, deliberately outside it.

### Phase 1: Safety harness and freeze the writers

**Rationale:** Every item is tagger-independent, several protect irreplaceable assets, and one
(wrtag's live rw mount) is an active hazard confirmed to be costing nothing to remove. Nothing here
waits on the spike.
**Delivers:**
- `scrub: auto: no`, `lastgenre: auto: no`, `embedart: auto: no` in **every** beets config in the
  repo (`arrs/beets/`, `soulbeet/`, and the `audio.bash` one at `/config/scripts/beets-config.yaml`)
- Jellyfin: `SaveLocalMetadata` off for the Music library, scheduled scans paused, database backed up
- `zfs snapshot tank/media/Music@pre-project` + copies of both `library.db`, taken together
- `ffprobe` JSON tag dump of all 794 `dj-mixes` files → the DJ recovery artefact
- `rsync -rlt --no-p --no-o --no-g` copy of the 54 cover scans to a path no tagger can write
- wrtag container stopped, `/mnt/tank/media/Music` mount **removed from the definition**
- Lidarr `renameTracks` off, root folder repointed off `/media/Music`
- **Library ownership normalised to one decided uid:gid**, recorded — currently 12 of 13 artist
  folders are `apps:nogroup` (568:65534) and one is `apps:apps` (568:568), matching neither
  `beets.md` (568:545) nor `CLAUDE.md` (568:568). Something has been writing with an unmapped gid.
- Write-probe: import one album, verify with `ffprobe` on the file and `stat -c '%u:%g %a'`

**Addresses:** T2, T3, T12 from FEATURES.md. **Avoids:** Pitfalls 1, 2, 5, 10, 13.
**Exit:** exactly one process holds a rw path to the library, verified by inspecting the mounts of
*running* containers — not by reading compose files.

### Phase 2: NFS export + Music Assistant reachability spike

**Rationale:** Depends on nothing, runs in parallel with 1 and 3, and resolves the only unresolved
conflict in the research. MA never purges stale entries (Pitfall 12), which inverts the natural
order: prove MA on three final albums *before* anything is imported, not after.
**Delivers:** NFSv4 export from the Proxmox host under Terraform (`ro`, restricted to 172.16.1.31,
Music dataset only, squashed to the uid:gid decided in Phase 1); the HAOS-vs-MA-provider test above,
executed and recorded; 3 albums visible in MA and still visible after a NUC reboot.
**Implements:** ARCHITECTURE Pattern 7 (read-only fan-out). **Uses:** STACK's NFS-over-SMB rationale.

### Phase 3: Tagger spike

**Rationale:** ARCHITECTURE imposes the one hard requirement — *the single writer must be able to
own the whole tree, including content that will never match MusicBrainz.* If the answer to "what
happens to Mastermix?" is "it lives outside the tool", the tool has failed the requirement that
matters most here.
**Delivers:** a decision recorded with numbers. Protocol: run the 5-minute wrtag disqualifier first
(`docker logs wrtag`, then one `wrtag move -dry-run` on a throwaway album — if the path format does
not render, that *is* the wrtag result); normalise ~20 DJ folders **before** measuring Discogs
coverage; count folders where a Discogs candidate appears at all; time 20 imports with `discogs`
enabled to extrapolate against the 60 req/min authenticated ceiling.
**Overturning thresholds already defined in STACK:** Discogs matching < ~40% of `dj-mixes` after
normalisation, or Discogs rate limiting making bulk impractical, or an honest self-assessment that
the interactive prompt will not be sat at. **Non-evidence:** wrtag's 0.x version number, and the
current container's brokenness (that is the inverted pin, fixable in one line).

### Phase 4: Collapse to one tagger

**Rationale:** Correctness prerequisite for Phase 7, not cleanup. Also the one phase that must be
**independently shippable** — if this attempt stalls like the previous three, the estate is still
strictly better than it started: one tagger, one database, no idle container holding a rw mount.
That is the insurance policy against attempt five inheriting attempt four's wreckage.
**Delivers:** losing tagger definitions deleted, Renovate rules released (including the wrtag
`<0.30.0` pin that is enforcing the broken state), `soulbeet` removed (issue #306), the beets block
stripped from `audio.bash`, and the **missing `musicbrainz` plugin defect fixed in every config**.
**Addresses:** T1. **Avoids:** Pitfalls 4, 5, 6, 7.

### Phase 5: Inbox structure + bucket D triage

**Rationale:** Junk in the sample corrupts every subsequent measurement, and the mega-folder problem
must be solved before anything is queued.
**Delivers:** `_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}` under
`tank/downloads` (never under `media/`); `_FAILED_`/`_UNPACK_`/stray `.rar`/the Harry Potter BluRay
rip quarantined; the 45 GB `Now! 1-115` folder split per volume before it can become one
un-abortable 115-album import.
**Addresses:** T6, T13. **Implements:** ARCHITECTURE Patterns 2 and 5.
**Note:** `_`-prefixed names are fine *here* because this is outside the library. They must never
appear **inside** the library tree — MA silently ignores underscore-prefixed folders and Jellyfin
does not, so the two consumers would diverge by design.

### Phase 6: Tagger configuration + dry run

**Rationale:** Config belongs to the surviving tagger, and the dry run is the last cheap moment to
catch a path-format error before it is applied at scale.
**Delivers:** `copy: yes` / `move: no`; `incremental: yes` **with `incremental_skip_later: yes`**;
`import.log` set; `importsource` on; path formats where the top-level folder equals `ALBUMARTIST`
exactly (`Various Artists/`, not `Compilations/`); `;` as the multi-artist delimiter;
`match.preferred.countries: ['GB|UK','US']` (MusicBrainz stores the UK as **`GB`** — `['UK']`
silently matches nothing, and entries are regexes) plus `preferred.original_year: yes` plus
`musicbrainz.extra_tags`; `fetchart` at folder level with `embedart.auto: no`.
**Addresses:** T7, T9, T10, T11, D11. **Exit:** `beet import --pretend` output on a sample of each
bucket matches the intended tree.

### Phase 7: Pilot — ~12 bucket-A albums, end to end

**Rationale:** The first countable, visible result. Twelve is enough to prove every layer and small
enough to finish in one evening. Every prior attempt failed by shipping a tool instead of an album.
**Delivers:** 12 albums inside a snapshot fence, verified with `ffprobe` on the files, `stat` on
ownership, visible in Jellyfin with the *new* metadata, and visible in Music Assistant under the
correct album artist. Plus the post-commit detection sweep run for the first time (`.1`-suffix
collision search, `mb_albumid::` empties, track-count-vs-`tracktotal`).
**Addresses:** T8, T14. **Exit:** the definition of done for this project, exercised once.

### Phase 8: Close the inflow — the one ingest path

**Rationale:** PITFALLS' highest-leverage sequencing decision, and it inverts the intuitive order.
Working a backlog while Lidarr keeps adding untagged content to it is unwinnable, and it *feels*
unwinnable, which is what actually stops people.
**Delivers:** SAB's hook does one cheap thing (`mv` the folder into an inbox) and exits — thin hook,
thick worker; persistent database; low-confidence content **routed to review, never silently
skipped**; a readable log.
**Addresses:** T4, T5. **Avoids:** Anti-patterns A1, A18 and Pitfall 3.
**Exit:** a real new download completes end to end with no `skip`.

### Phase 9: Bucket A in batches

**Rationale:** Never scale an unproven pipeline. Snapshot per batch, detection sweep after each,
batches small enough to finish in one sitting.
**Delivers:** the mainstream backlog imported. **Exit:** milestone complete per PROJECT.md.

### Beyond the milestone (explicitly not in scope — do not let "worth doing" become "in scope")

- **Duplicate reconciliation** — must precede any import of `unsorted`, since all 85 `dj-mixes`
  names collide with it and the library would otherwise get both.
- **Bucket B — the *Now!* series** — a manual budget, not a config fix. `preferred.countries` is a
  distance *weight*, not a filter, and cannot beat a candidate that matches better on content.
- **Bucket C — DJ content** — normalise, then Discogs, then scans. Separate library root.

### Phase Ordering Rationale

- **Harness before spike** because every harness item is tagger-independent and several protect
  assets that cannot be recreated. Neutralising a live writer is not the same as retiring a tagger.
- **NFS/MA in parallel from the start** because both candidate mount routes need the same export,
  the export is a Terraform change with no dependencies, and MA's inability to purge stale entries
  means it must be proven *before* content flows, not after.
- **Spike before retirement** because you cannot retire the survivor — but the spike is scoped to
  produce a number, not to relitigate a direction that four independent lines of evidence agree on.
- **Junk gate before every import phase** because junk in the sample corrupts the evidence.
- **Pilot before ingest before scale.** The pilot is small and early so there is an early win; the
  ingest path closes the inflow before the backlog opens; the bulk import comes last because it is
  the only phase that is purely throughput.
- **Retirement is independently shippable** so a fourth stall still leaves the estate better off.

### Research Flags

**Phases likely needing `--research-phase` during planning:**

- **Phase 2** — the HAOS-vs-MA-provider conflict is genuinely unresolved between primary sources,
  and the mount-timing race is documented only in a community discussion. Needs the empirical
  protocol written into the plan, with route B pre-specified so a FAIL does not stall the phase.
- **Phase 3** — the spike is itself research, but the *plan* needs a defined evidence protocol with
  pre-committed thresholds, or it will drift into tool advocacy. The normalisation pre-step is easy
  to omit and would invalidate the result.
- **Phase 8** — SABnzbd hook semantics (serial queue, no script timeout, detaching loses the exit
  code) and the notify/route design need working through; the naive version is exactly what is
  failing today.
- **Post-milestone DJ phase** — LOWEST confidence area in the whole research. No established
  community pattern exists for this specific field rotation, and it is unknown whether the trailing
  numbers in titles are uniformly BPM.

**Phases with standard patterns (skip research):**

- **Phase 1** — every item is a documented config change or a standard ZFS/rsync operation.
- **Phases 4, 5, 6, 7, 9** — beets configuration, filesystem triage and batch import are extensively
  documented, and the specific traps (`incremental_skip_later`, `GB` not `UK`, `scrub.auto`,
  `quiet_fallback`) are already captured in PITFALLS.md and STACK.md with citations.

---

## Corrections to Existing Project Documents

Everything below is now known to be wrong or incomplete and should be fixed in place.

### `.planning/PROJECT.md`

| # | Location | Correction |
|---|---|---|
| 1 | Constraints — *"Mastermix, DMC, Music Factory, Crate, Toolkit and Essential Hits are not catalogued in MusicBrainz. No autotagger will ever match them"* | **Overstated.** ~46 entries exist across those labels (18 `Mastermix Issue`, 19 `DMC Commercial Collection`, 9 `Music Factory Mastermix`), clustered 2011–2016. `Crate` and `Toolkit` are genuinely zero. This backlog's own issues (430/433/441/444) are zero. Where entries exist they are frequently 5–10 track **stubs** against 15–20 track releases — *more* dangerous than absence. And **Discogs carries 430, 433 and DMC 350 outright**. Rewrite to: coverage stops ~2016 and excludes this backlog; surviving entries are stubs and must never be accepted without a track-count check; Discogs is the source for this content. |
| 2 | Context — *"the mount has to be added through Home Assistant's own storage configuration"* | Stated as fact; it is **unresolved**. MA's own docs state a folder cannot be mounted from HA into `/media`, and the "Filesystem (remote share)" provider is the documented alternative. Reword as an open question and attach the empirical test above. |
| 3 | Constraints — ZFS section | **Missing:** `/mnt/tank/downloads` and `/mnt/tank/media/Music` are **separate ZFS datasets** (confirmed in `infra/lxc-selfhost.tf`). Every library "move" is copy-then-unlink, not an atomic rename — interruptible, needs transient double space, and `cp --reflink` fails `EXDEV` across them. |
| 4 | Constraints — *"back up both beets `library.db` files before any bulk run"* | Necessary but insufficient. Add: a `zfs snapshot` of `tank/media/Music` taken **in the same step** (rolling back only one leaves `incremental` state lying); the `ffprobe` tag-dump JSON of `dj-mixes`; and the cover-scan archive copy. |
| 5 | Context — the four-entry-point table | **Missing a fifth writer.** Lidarr's root folder is `/media/Music` with `renameTracks: True` — it has been actively renaming files inside the shared library tree. Add the row, and add repointing it to the Active requirements. |
| 6 | Context — the `audio.bash` row | The `skip` cause is now known and is **neither** the threshold **nor** the content. `/config/scripts/beets-config.yaml` declares `plugins: embedart` and nothing else; since beets 2.4.0 MusicBrainz is a plugin, so that config has **no metadata source at all** and every album must skip. Record the cause so nobody "fixes" it with `quiet_fallback: asis`. |
| 7 | Constraints — *"then `chown -R 568:545`"* (inherited from `beets.md`) | **Does not match the library.** 12 of 13 artist folders are `apps:nogroup` (**568:65534**), 1 is `apps:apps` (**568:568**). This matches neither `beets.md` (568:545) nor `CLAUDE.md` (568:568). Ownership must be *decided and normalised*, not assumed — and the decided value sets `anonuid`/`anongid` on the NFS export. |
| 8 | Context — *"27 of 85 `dj-mixes` folders contain any image (54 files total)"* | **Confirmed correct** on the host. No change; recorded as verified. The Harry Potter BluRay rip in `dj-mixes` is also confirmed. |

### `stacks/selfhosted/arrs/beets.md`

| # | Location | Correction |
|---|---|---|
| 9 | ~L101 — *"Mastermix, DMC, Music Factory, Crate, Toolkit and Essential Hits are not in MusicBrainz"* | Same as #1. |
| 10 | ~L124 — `albumtype:dj: DJ-Mixes/$album/$track $title` | A `DJ-Mixes/` folder matches **no tag**, which is the documented Jellyfin duplicate-artist trigger (#12845, #11190) and breaks MA's `/artist/album` albumartist fallback. It also still pollutes the main artist list. Replace with a **separate library root** registered as its own Jellyfin library and its own MA provider, structured so the top-level folder equals `ALBUMARTIST`. |
| 11 | ~L159 — `chown -R 568:545` | Same as #7 — not what is on disk. |
| 12 | The `beet import -A` prescription for DJ content | Two omissions. `-A` faithfully preserves the **broken field mapping**, making DJ content confidently wrong rather than merely untagged — normalisation must come first. And with `scrub` enabled (`auto` defaults to **yes**) `-A` additionally destroys every field beets does not model: BPM, issue numbers, mix/version, key. Add `scrub: auto: no` and the normalise-first ordering. |
| 13 | ~L28 — *"They keep separate `library.db` files but write to the same tree"* (two beets, one library) | Understated. **Four** state stores claim authority over the tree, plus Lidarr as an active renamer. |

### `stacks/selfhosted/music/wrtag.yaml`

| # | Location | Correction |
|---|---|---|
| 14 | Header — *"Automatic metadata lookup from MusicBrainz, **Discogs**, and other sources"* | **False.** wrtag is MusicBrainz-only by design, permanently; "discogs" appears zero times in the v0.33.0 README except as a user-supplied `WRTAG_RESEARCH_LINK` — a hyperlink for a human, not a metadata source. This misdescription is plausibly why wrtag was adopted for DJ content in the first place. |
| 15 | Header — *"Designed for DJ collections (Mastermix, CD Pool, DMC, Music Factory)"* | The tool cannot source metadata for **any** of them. |
| 16 | Pin comment — *"v0.30.0 changed path-format fields — pinned to last compatible version"* | **Inverted.** The `WRTAG_PATH_FORMAT` in this file is v0.30+ syntax (`.Track.Position`, `.Media.Position`) running on a **v0.20.0** binary, which hard-sets `Track.Position = -1` and has no `.Media` in its `Data` struct at all. v0.20.0 is the *incompatible* one; the existing format string is already correct for v0.33.0. Startup validation never catches it because `validate()` only builds single-medium examples. **Confirmed empirically: no `Compilations/` directory exists — wrtag has never written anything.** |
| 17 | Renovate rule pinning wrtag `<0.30.0` | It is enforcing the broken state, and it was added on a misdiagnosis (2026-06-24). Release it, or delete the stack. |
| 18 | `- /mnt/tank/media/Music:/music/library` (rw) | A **live second writer** on the library, `restart: unless-stopped`, since January. Remove the *mount*, not just the restart policy — a stopped container with a rw mount is a loaded gun, and this estate has already lost six weeks to unnoticed `created`-state containers. |

### Also (outside the requested three, same defect class)

| # | File | Correction |
|---|---|---|
| 19 | `stacks/selfhosted/arrs/soulbeet/beets_config.yaml` | Custom `plugins:` list `[fetchart, embedart, lastgenre, scrub, replaygain, missing, duplicates]` — **no `musicbrainz`**, so on beets ≥ 2.4.0 it has no metadata source. Also `move: yes`, `scrub` with no `scrub:` section (`auto` defaults yes), `lastgenre: auto: yes`, `embedart: auto: yes`. Every one is a documented hazard. Being retired anyway (#306), but the `plugins:` defect must not be copied into the surviving config. |
| 20 | `stacks/selfhosted/media/jellyfin.yaml` | `/mnt/tank/media` is mounted **rw** with no `:ro`. Jellyfin should be a reader only. |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | **HIGH** | Tagger comparison and version data read directly from tagged upstream source (`wrtag` v0.20.0 and v0.33.0 `pathformat.go`), live MusicBrainz WS/2 and Discogs API queries, PyPI/GitHub release data. MEDIUM only on OCR (no source benchmarks album artwork specifically) and on the ZFS-side NFS permission specifics. |
| Features | **HIGH** | beets behaviour verified against official docs including the *negative* claim (no `beet undo`, checked against the live command list). Jellyfin and MA requirements from official docs plus corroborating issue reports. MEDIUM on community practice patterns. **LOW** on the DJ field-remap design — no established pattern exists for this rotation. |
| Architecture | **MEDIUM-HIGH** | Component semantics from official docs; the single-writer principle is derived, not cited, but is strongly supported by this estate's own failure history. beets-flask specifics verified from published docs but not run here. Several of its "to verify on the host" items have since been checked and **one contradicted its assumption** (Lidarr's root folder). |
| Pitfalls | **HIGH** on tool behaviour (beets/wrtag/Jellyfin/MA docs and source verified); **MEDIUM** on this estate's ZFS/HAOS specifics (documented behaviour, not yet observed here); **MEDIUM** on the abandonment analysis (reasoned from this project's own three-failure history plus community evidence, not formal post-mortems). |

**Overall confidence: MEDIUM-HIGH.** The direction is well-evidenced and the traps are unusually
well-documented. The residual uncertainty is concentrated in two places — the HAOS mount route and
the DJ field-mapping work — and both are already scoped so that discovering a problem there does
not invalidate the milestone.

### Gaps to Address

| Gap | How to handle |
|---|---|
| **HAOS `/media` mount vs MA remote-share provider** — primary sources contradict each other | Phase 2, empirical test above, 3 albums, both routes pre-specified. Build the NFS export first since both routes need it. Record as a Key Decision either way. |
| **Discogs match rate on `dj-mixes` after normalisation** — unknown, and it is the number that decides the tagger | Phase 3 spike, with the ~20-folder normalisation pre-step. Threshold pre-committed at ~40%. |
| **Correct library ownership uid:gid** — three documents disagree and reality (568:65534 on 12 of 13 folders) matches none of them | Phase 1. This must be *decided*, not looked up. Also worth understanding *why* `nogroup` appeared — some writer has been running with an unmapped gid, which is a live clue about which one. |
| **Are the trailing numbers in DJ titles uniformly BPM?** | Determines whether the remap can be scripted or must be semi-manual. Guard the strip to a plausible 60–200 range and log every change — legitimate titles can end in a number (`"1999"`, `"Summer of '69"`). Sample before scripting. |
| **Do Jellyfin and MA both tolerate a second library root cleanly?** | Jellyfin has open multi-root artist-duplication issues (#12764, #12976). Test with three albums before committing the DJ tree. Post-milestone. |
| **Discogs rate limiting at bulk scale** (60 req/min authenticated) | Time 20 folder imports in the spike and extrapolate. If impractical, it is one of the pre-committed conditions that reopens the tagger question. |
| **The interactive-attention budget** | An honest self-assessment, not a measurement — but it decides the tagger as much as any number does. If the answer is "I will not sit at a prompt", the plan needs the preview/review UI *inside* the milestone rather than after it. |

---

## Sources

### Primary (HIGH confidence)

- `github.com/sentriz/wrtag` tagged source at **v0.20.0** and **v0.33.0** — `pathformat/pathformat.go`,
  `musicbrainz/musicbrainz.go`, `README.md`; GitHub Releases API for the v0.30.0 BREAKING CHANGES table
- **MusicBrainz WS/2 API** — live exact-title release queries for Mastermix / DMC / Music Factory /
  Pro Disc across issue numbers 300–485, plus the `Mastermix: DJ Beats` series entity and its
  entry-guidance annotation (Album + Compilation, never `DJ Mix`)
- **Discogs API** `database/search` — live queries for the same issue numbers
- `github.com/beetbox/beets` — `docs/changelog.rst`, configuration reference, CLI reference
  (command set verified for the *absence* of `undo`), and the `scrub` / `duplicates` / `chroma` /
  `discogs` / `zero` / `edit` / `fromfilename` / `importsource` / `unimported` / `badfiles` /
  `musicbrainz` plugin docs; `beets/util/__init__.py` for `unique_path` no-clobber `.1` behaviour
- `github.com/home-assistant/supervisor` — `supervisor/mounts/mount.py` (`NFSMount.options` hardcoded,
  `NetworkMount.read_only`)
- `github.com/music-assistant/home-assistant-addon` — `music_assistant/config.yaml`
  (`map: [media:rw]`, `privileged: SYS_ADMIN, DAC_READ_SEARCH`, v2.9.13)
- Music Assistant docs — [filesystem source](https://www.music-assistant.io/music-providers/filesystem/)
  (HAOS `/media` restriction, Album Artist mandatory, `;`-only splitter, underscore/UTF-8/emoji
  skipping) and [Jellyfin source](https://www.music-assistant.io/music-providers/jellyfin/)
  (no dedicated developer, best-effort)
- Jellyfin docs — [music library](https://jellyfin.org/docs/general/server/media/music/),
  [NFO metadata priority](https://jellyfin.org/docs/general/server/metadata/nfo/),
  [excluding directories](https://jellyfin.org/docs/general/server/media/excluding-directory/)
- [Home Assistant OS network storage](https://www.home-assistant.io/common-tasks/os/) — usage types,
  HAOS >= 10.2 requirement
- [Servarr wiki — Lidarr and beets integration](https://wiki.servarr.com/lidarr/beets-integration)
- [MusicBrainz Picard introduction](https://picard-docs.musicbrainz.org/en/latest/about_picard/introduction.html)
  — explicit scope disclaimer on mass tagging
- **Repository evidence, read directly:** `infra/lxc-selfhost.tf` (unprivileged LXC; separate
  `mount_point` blocks confirming distinct datasets), `stacks/selfhosted/music/wrtag.yaml`,
  `stacks/selfhosted/arrs/soulbeet/beets_config.yaml`, `stacks/selfhosted/arrs/lidarr.yaml`,
  `stacks/selfhosted/media/jellyfin.yaml`, `stacks/selfhosted/arrs/beets.md`, `.planning/PROJECT.md`,
  `NETWORK.md`
- **Host verification, 2026-08-17:** absence of `Compilations/`; Lidarr root folder + `renameTracks`;
  library ownership distribution; `/config/scripts/beets-config.yaml` plugin list; `dj-mixes` image
  census; misfiled BluRay rip

### Secondary (MEDIUM confidence)

- beets-flask [configuration](https://beets-flask.readthedocs.io/latest/configuration.html) and
  [inboxes](https://beets-flask.readthedocs.io/v1.0.0/inboxes.html) — single `library.db` shared
  across N policy-carrying inboxes; `autotag: no|preview|auto|bootleg`
- Jellyfin issues — [#12845](https://github.com/jellyfin/jellyfin/issues/12845),
  [#11190](https://github.com/jellyfin/jellyfin/issues/11190) (folder/tag duplicate artist);
  #13655, #13350, #16356 (NFO precedence, refusal to refresh); #4728, #12297, #11625, #14589
  (move/scan damage); [#14502](https://github.com/jellyfin/jellyfin/issues/14502) (`.ignore`);
  [features #3121](https://features.jellyfin.org/posts/3121/) (no orphan cleanup)
- beets issues — [#360](https://github.com/beetbox/beets/issues/360) (chroma *degrades* compilation
  matching), [#2611](https://github.com/beetbox/beets/issues/2611) (permissions plugin misses
  directories), [#6728](https://github.com/beetbox/beets/issues/6728) (lyrics has no throttling)
- Music Assistant support — [#4877](https://github.com/music-assistant/support/issues/4877)
  (deleted media never removed), [#4846](https://github.com/music-assistant/support/issues/4846)
  (stale entries after rename), [discussion #452](https://github.com/orgs/music-assistant/discussions/452)
  (mount-timing race)
- OpenZFS — [#15345](https://github.com/openzfs/zfs/issues/15345),
  [#18005](https://github.com/openzfs/zfs/issues/18005) (`reflink` `EXDEV` across datasets),
  [#13408](https://github.com/openzfs/zfs/issues/13408) (`chmod` EPERM under `aclmode=restricted`)
- [linuxserver/docker-beets #68](https://github.com/linuxserver/docker-beets/issues/68) —
  PUID/PGID does not grant ownership
- SABnzbd forums — post-processing is serial, no built-in script timeout, detaching loses the exit code
- Proxmox forum — NFS server in an unprivileged LXC is not supported

### Tertiary (LOW confidence — needs validation)

- 2026 OCR/VLM landscape synthesis (OCR Arena positions, PaddleOCR-VL / GLM-OCR OmniDocBench scores,
  VLM-vs-traditional accuracy on noisy backgrounds, self-host break-even volumes) — no source
  benchmarks album artwork specifically; run a 5-image eval before committing
- HAOS/NFS permission symptoms — mechanism confirmed from Supervisor source, symptoms from
  community reports only
- DJ field-mapping remap design — no established community pattern found for this rotation

---
*Research completed: 2026-08-17*
*Ready for roadmap: yes*
