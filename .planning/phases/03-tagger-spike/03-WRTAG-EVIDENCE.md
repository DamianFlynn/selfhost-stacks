# Phase 3 criterion 3: the wrtag path-format disqualifier, measured

Companion to [`03-DECISION.md`](03-DECISION.md) (the pre-committed thresholds and the criterion 4
table this document supplies the wrtag rows for) and to
[`stacks/selfhosted/music/wrtag.yaml`](../../../stacks/selfhosted/music/wrtag.yaml) (the frozen
definition this phase reads and quotes but never edits, D-03).

Nothing here is applied by `docker compose`. This is the record of what three wrtag versions do
with **this repository's own `WRTAG_PATH_FORMAT`**, on two disc classes, measured at runtime and
cross-checked against source.

Measured 2026-09-03 on LXC 100 by
[`scripts/spike03-wrtag-arms.sh`](../../../scripts/spike03-wrtag-arms.sh). Every arm was a
`wrtag move -dry-run` with the source bind-mounted `:ro` and the destination on scratch. **No arm
wrote a byte**, asserted per arm on both mounts by two independent instruments. Raw captures at
`/mnt/fast/spike-03/out/wrtag-*.{stdout,stderr,meta}`; before/after subtree manifests at
`/mnt/fast/spike-03/out/manifests/`.

> **The pin is not simply inverted, and D-01's, `renovate.json5:91`'s, `PROJECT.md`'s and
> `CLAUDE.md`'s stated evidence is wrong in three separate ways. Measured, not argued:**
>
> 1. **Of the four fields `renovate.json5:91` implicates, all four exist at v0.20.0.** The rule
>    says v0.30.0 "reworked" `.Release.Date.Year`, `.Release.Media`, `.Track.Position` and
>    `artistsString`. `.Release.Date.Year` rendered as `(2023)` at v0.20.0 in this run;
>    `.Release.Media` is read by v0.20.0's own `validate()`; `.Track.Position` is a field of
>    `musicbrainz.Track` at v0.20.0; `artistsString` is registered in v0.20.0's template funcs at
>    `pathformat.go:204`. **The rule names four innocent things and misses both real defects.**
>    The one field genuinely absent from v0.20.0 is **`.Media`** — which the rule does not name.
> 2. **The real v0.20.0 defect is `d.Track.Position = -1`** (`pathformat.go:113-115`, under the
>    literal comment `// make sure these are not used`), so **every single-disc release renders
>    `-1 - Title.ext`**. Demonstrated: 21 of 21 rendered paths in the v0.20.0 single-disc arm.
>    `{{ .Media.Position }}` hard-errors too, but **only** on multi-disc, because it sits behind
>    `{{ if gt (len .Release.Media) 1 }}` and Go evaluates `{{ if }}` bodies lazily.
> 3. **And the headline nobody had: v0.33.0 and v0.34.0 REFUSE THIS REPO'S PATH FORMAT AT
>    STARTUP.** `validate: ambiguous format: multiple directories created for the same release`,
>    exit **2**, before a single file is read. So the claim in `CLAUDE.md` § *What NOT to Use*
>    (*"`v0.33.0` — the existing path format is already correct for it"*), in `PROJECT.md`
>    § *Version Compatibility* (*"Breaking. **Not used by this repo's format**"*) and in
>    `03-RESEARCH.md`'s State of the Art (*"no path-format change"*) is **FALSIFIED**.
>    **Both ends of the pin are broken. v0.20.0 runs and produces garbage; v0.33.0 and v0.34.0
>    fail closed.** Releasing the Renovate pin without migrating the format first would not
>    "break music tagging again" — it would stop wrtag from starting, which is strictly the
>    safer of the two failures and the opposite of what the rule predicts.
>
> **Phase 4's TAGR-03 must cite this, not the field list.** Rewriting the rule to name the same
> four fields with the version numbers swapped would carry the same wrong analysis forward.

---

## The six arms

One album, one path format, one command. The arms differ by image tag and by the pinned
MusicBrainz release, and by nothing else.

- **Album:** `Taylor.Swift-1989..Taylors.Version.-WEB-2023-MyMo` — 21 MP3, flat, no `disc` tag,
  `track=N/21` on every file. Reflinked into
  `/mnt/tank/downloads/spike-03/wrtag-src/` on atlantis (`cp -r --reflink=always
  --preserve=timestamps`, then `chown 568:568` — the 03-03 route, because `FICLONE` is EPERM
  inside the unprivileged container).
- **Path format:** extracted at run time from `stacks/selfhosted/music/wrtag.yaml` line 71.
  **sha256 `3d977d432d16dd51c04c8dbbc3998b2a1f696288c03b885f5ce03c3660df1bee`**, 307 bytes. Never
  re-typed; re-extract and compare with
  `grep -m1 '^      - WRTAG_PATH_FORMAT=' stacks/selfhosted/music/wrtag.yaml | sed 's/^[^=]*=//' | tr -d '\n' | sha256sum`.

| # | Tag | Disc class | Pinned MBID | Startup validation | Rendered path | Errored? | Container exit | Wrote nothing? |
|---|---|---|---|---|---|---|---|---|
| 1 | **v0.20.0** | single-disc | `9b0c97d3…` (CD, 1 medium, 21 tracks) | **passes** | `…/1989 (Taylor's Version) (2023)/`**`-1 - `**`Welcome to New York (Taylor's version).mp3` — and 20 more, **21 of 21 begin `-1 - `** | no | 0 | ✅ both instruments |
| 2 | **v0.20.0** | multi-disc | `b08e07b5…` (2×12" vinyl, 11+10) | **passes** | **none — template execute error** | **yes**, naming `Media` | 1 | ✅ both instruments |
| 3 | **v0.33.0** | single-disc | `9b0c97d3…` | **REFUSED** | **none — the process never ran** | n/a (pre-run) | **2** | ✅ both instruments |
| 4 | **v0.33.0** | multi-disc | `b08e07b5…` | **REFUSED** | **none** | n/a (pre-run) | **2** | ✅ both instruments |
| 5 | **v0.34.0** | single-disc | `9b0c97d3…` | **REFUSED** | **none** | n/a (pre-run) | **2** | ✅ both instruments |
| 6 | **v0.34.0** | multi-disc | `b08e07b5…` | **REFUSED** | **none** | n/a (pre-run) | **2** | ✅ both instruments |

Arm 2's error, verbatim:

```
level=ERROR msg=running command=move err="processing: gen dest dir: create path: create path:
template: template:1:135: executing \"template\" at <.Media.Position>:
can't evaluate field Media in type pathformat.Data"
```

Arms 3–6's refusal, verbatim and byte-identical across all four:

```
validate: ambiguous format: multiple directories created for the same release (NOTE: wrtag
v0.30.0 changed the data available to path-format. if your config is from v0.2x, you need to
migrate. please see https://github.com/sentriz/wrtag/releases/tag/v0.30.0)
```

The v0.33.0 pair's stderr is byte-identical to itself
(`8326eaa4dd2ab555f76df2f3859d44b6cb7b35c44269ffbcbe66377b6f60803f`), as is the v0.34.0 pair
(`6dd54332595a0771db1ce4b26029f312a4cbc0c44a0bd464291f1606c6154ec1`) — the two differ only in the
`Usage:` block that follows, because the two versions have different flags. **The refusal is
identical for both disc classes, which is itself the proof that it is a startup check and not a
per-release one.**

### The disc class is a property of MusicBrainz, not of the folder

Recorded because it changed how these arms had to be run, and because it will bite anyone who
repeats them.

The **first** arm was run unpinned. A 21-file, no-`disc`-tag, `track=N/21` folder — about as
unambiguously single-disc as source material gets — was resolved by MusicBrainz to
`b08e07b5-dbc3-4dcc-815d-5aeffe465b33`, *"1989 (Taylor's version)", Sunrise Boulevard yellow
edition vinyl*, **two 12" media of 11 and 10 tracks**, and v0.20.0 promptly hard-errored on
`.Media.Position`. wrtag issues one query with `limit=1` and takes what comes back:

```
https://musicbrainz.org/ws/2/release?fmt=json&limit=1&query=release:(1989 \(taylor's version\))
  artist:(taylor swift) date:(2023\-01\-01) tracks:(21)^10
```

That capture is kept at `wrtag-v0.20.0-natural-unpinned.stderr` because it is evidence in its own
right: **the multi-disc failure is not an exotic case that requires a box set. It fires on an
ordinary single-CD rip whenever MusicBrainz happens to return a vinyl edition.** There are
currently at least two two-medium releases among the twelve MB releases matching this album at
score 100.

It also means the disc class cannot be held constant by choosing a folder. The six arms therefore
pin the release with `-mbid`, the **same MBID given to all three tags of a class**, so the only
difference within a class is the image and the only difference between classes is
`len(.Release.Media)`. The two releases were chosen from the same MB query, both score 100, both
21 tracks:

| Class | MBID | Title | Format | Media |
|---|---|---|---|---|
| single-disc | `9b0c97d3-d159-4822-9987-fe6a1dd628bb` | *1989 (Taylor's Version)*, Sunrise Boulevard yellow edition | CD | **1** × 21 |
| multi-disc | `b08e07b5-dbc3-4dcc-815d-5aeffe465b33` | *1989 (Taylor's version)*, Sunrise Boulevard yellow edition vinyl | 12" Vinyl | **2** × (11, 10) |

The two MB titles differ in the capitalisation of *Version*, which is why the two classes render
different directory components. That is MusicBrainz's data, not a rendering difference.

### The ablation — what the disc SUBDIRECTORY costs, isolated

Arms 3–6 answer criterion 3 completely (*"can this repo's format run on a current wrtag?"* — no),
but they cannot answer *"does a current wrtag render a real per-disc track position?"* or *"do
v0.33.0 and v0.34.0 render identically?"*, because they never render anything. Six further arms
were run through the **same script and the same extraction code path**, with `WRTAG_YAML` pointed
at [`03-wrtag-ablation-format.yaml`](03-wrtag-ablation-format.yaml) — **the same format with the
disc component moved out of the directory and into the filename, and nothing else changed**.

Ablation format sha256 `3a38b604ad88ab07e4814200fdec11b92c3b61ba8835a3a0326bfb813e79d5b5`.
It is **not** a proposed migration; choosing one is TAGR-03's job.

| # | Tag | Class | Startup validation | Rendered path (first track) | Exit | Wrote nothing? |
|---|---|---|---|---|---|---|
| A1 | v0.20.0 | single-disc | passes | `…/1989 (Taylor's Version) (2023)/`**`-1 - `**`All You Had to Do Was Stay…` | 0 | ✅ |
| A2 | v0.20.0 | multi-disc | passes | none — same `<.Media.Position>` error | 1 | ✅ |
| A3 | **v0.33.0** | single-disc | **PASSES** | `…/1989 (Taylor's Version) (2023)/`**`01 - `**`Welcome to New York (Taylor's version).mp3` | 0 | ✅ |
| A4 | **v0.33.0** | multi-disc | **PASSES** | `…/1989 (Taylor's version) (2023)/`**`Disc 1-01 - `**`Welcome to New York…` | 0 | ✅ |
| A5 | **v0.34.0** | single-disc | **PASSES** | byte-identical to A3 | 0 | ✅ |
| A6 | **v0.34.0** | multi-disc | byte-identical to A4 | byte-identical to A4 | 0 | ✅ |

**Three things fall out of this, and each is load-bearing:**

1. **The disc subdirectory is the sole cause of the startup refusal.** One change, and the format
   validates at both current tags. Nothing else in the format is implicated — not
   `.Release.Date.Year`, not `.Release.Media`, not `.Track.Position`, not `artistsString`.
2. **v0.33.0 and v0.34.0 render a real per-disc track position**, `01`…`21` on the single-disc
   arm and `Disc 1-01`…`Disc 1-11`, `Disc 2-01`…`Disc 2-10` on the multi-disc arm — the real
   11/10 split of the vinyl release. **Zero `-1 - ` components in any of the four.** Against 21
   of 21 at v0.20.0. That is the demonstration, and it is a rendered path, not an assertion.
3. **The v0.20.0 arms behave identically under the ablation** — `-1 - ` on single-disc, the same
   `.Media.Position` error on multi-disc — which proves the v0.20.0 defect is in the *version*,
   not in the directory shape.

Byte-identity, computed over the `LC_ALL=C sort -u` set of rendered destination paths:

| Class | v0.33.0 | v0.34.0 | Identical? |
|---|---|---|---|
| single-disc (21 paths) | `860581e19a236c3d…` | `860581e19a236c3d…` | **yes** |
| multi-disc (21 paths) | `a12d113cff2d4899…` | `a12d113cff2d4899…` | **yes** |

---

## The corrected pin-inversion proof

The runtime demonstration above and the static source read below are recorded together and were
required to agree before either was written down. **They agree.**

### `type Data struct` at v0.20.0 — verbatim, `pathformat/pathformat.go:133-141`

```go
type Data struct {
	Release               musicbrainz.Release
	ReleaseDisambiguation string
	Ext                   string
	Track                 musicbrainz.Track
	Tracks                []musicbrainz.Track
	TrackNum              int
	IsCompilation         bool
}
```

### `type Data struct` at v0.34.0 — verbatim, `pathformat/pathformat.go:86-91`

```go
type Data struct {
	Release musicbrainz.Release
	Media   musicbrainz.Media
	Track   musicbrainz.Track
	Ext     string
}
```

### The forced `-1`, verbatim, v0.20.0 `pathformat/pathformat.go:113-115`

```go
	// make sure these are not used
	d.Track.Number = ""
	d.Track.Position = -1
```

`grep -c "Track.Position = -1"` returns **1** at v0.20.0 and **0** at both v0.33.0 and v0.34.0.

### Field-by-field, against what `renovate.json5:91` claims

| Field the rule names | Present at v0.20.0? | Evidence |
|---|---|---|
| `.Release.Date.Year` | **yes** | rendered as `(2023)` in arm 1's 21 paths |
| `.Release.Media` | **yes** | `release.Media = append(release.Media, media)` in v0.20.0's own `validate()`; and `{{ if gt (len .Release.Media) 1 }}` evaluated without error in arm 1 |
| `.Track.Position` | **yes**, and that is the problem | it is a field of `musicbrainz.Track`; v0.20.0 deliberately sets it to `-1` |
| `artistsString` | **yes** | registered in the template func map at `pathformat.go:204` |
| **`.Media`** *(not named by the rule)* | **NO** | absent from the struct above; the template execute error in arm 2 |

**Cause and effect are reversed in that rule, and its remedy is aimed at the wrong four
identifiers.** The v0.30.0 release notes' own migration table lists `.TrackNum`, `len .Tracks`
and `.Tracks` as the breaking changes — **none of which this repo's format uses**. The migration
table was read, correctly, as not applying to this repo; what was missed is that the *new
validation shipped in the same release* does.

### Agreement between the two instruments, stated

| Claim | Runtime | Source | Agree? |
|---|---|---|---|
| v0.20.0 forces track position to `-1` | 21 of 21 paths render `-1 - ` | `d.Track.Position = -1` present | **yes** |
| `.Media` is absent at v0.20.0 | `can't evaluate field Media in type pathformat.Data` | no `Media` field in the struct | **yes** |
| The `.Media` failure is lazily gated | arm 1 (1 medium) renders; arm 2 (2 media) errors | `{{ if gt (len .Release.Media) 1 }}` guards it; Go `text/template` evaluates `{{ if }}` bodies lazily | **yes** |
| v0.34.0 has a `Media` field and no forced `-1` | A4/A6 render `Disc 1-`/`Disc 2-` and real positions | struct above; `grep` returns 0 | **yes** |
| `IsCompilation` still available at v0.34.0 | the format parsed and executed at v0.33.0/v0.34.0 | `withLegacyFields()` at `pathformat.go:258-268` supplies `IsCompilation` and `ReleaseDisambiguation` | **yes** |

---

## Why startup validation never caught it

**v0.20.0's `validate()` constructs single-medium synthetic releases only.** Its release
constructor takes a flat `tracks ...string` and does exactly one append
(`pathformat.go:143-159`):

```go
	var media musicbrainz.Media
	for i, t := range tracks { … }
	release.Media = append(release.Media, media)
```

One medium, always. So `{{ if gt (len .Release.Media) 1 }}` is **false for every synthetic
release the validator builds**, the `{{ .Media.Position }}` inside it is never executed, and the
format passes startup. That is why this repo's broken format has passed startup for eight months
while producing `-1 - ` on every file it ever moved.

**v0.30.0 added exactly the missing case.** Its release notes list
*"**pathformat:** add validations for multi disc releases"* as a feature
([release v0.30.0](https://github.com/sentriz/wrtag/releases/tag/v0.30.0), published
2026-04-08). The block is `pathformat.go:186-206` at v0.34.0: build a two-medium release, render
every track, and refuse if `filepath.Dir(path)` is not the same for all of them.

```go
		release := newRelease("ar", "release-name",
			newMedia("track", "track"),
			newMedia("track", "track"),
		)
		var dir string
		for _, media := range release.Media {
			for _, track := range media.Tracks {
				path, err := f.Execute(release, media, track, "")
				…
				d := filepath.Dir(path)
				if dir != "" && d != dir {
					return fmt.Errorf("%w: multiple directories created for the same release", ErrAmbiguousFormat)
				}
				dir = d
			}
		}
```

This repo's format puts disc 1 in `Disc 1/` and disc 2 in `Disc 2/`. Two directories, one
release. **The validation that would have caught v0.20.0's silent breakage is the same validation
that rejects the format outright** — which is why the two findings are one finding, and why
"just unpin it" is not a fix.

---

## v0.33.0 versus v0.34.0

**A path-format no-op, and now measured rather than assumed.** OD-5 exists because D-01 names
v0.33.0 while v0.34.0 shipped on 2026-08-26; running both settles it without overriding a locked
decision.

- **Runtime:** identical. Both refuse this repo's format with byte-identical `validate:` text and
  exit 2. Under the ablation both render **byte-identical path sets** on both disc classes
  (sha256 `860581e1…` and `a12d113c…`, matching pairwise).
- **Source:** `pathformat/pathformat.go` at v0.33.0 and v0.34.0 both contain **zero**
  `Track.Position = -1` and both carry the `Media` field.
- **Changelog** ([release v0.34.0](https://github.com/sentriz/wrtag/releases/tag/v0.34.0),
  published 2026-08-26, commits dated 2026-08-24). The only breaking change is
  **`deps: bump to go1.27`**. Features: `cover-source`, `cover-max-size`,
  *"musicbrainz: retry on 503, bump retry limit to 5"*, and *"respect umask for directories as
  well"*. One fix: MusicBrainz client timeout to 60 s. **Nothing touches `pathformat`.**

**D-01 is honoured as written and the current release is measured.** Whichever of the two Phase 4
chooses, the path-format work is the same work.

*(One incidental datum for TAGR-03: the MusicBrainz 503 retry is not cosmetic here. Three arms in
this run hit `status=503` on the direct-release fetch and v0.20.0 gave up immediately —
`err="… musicbrainz returned non 2xx: 503"` — needing a manual re-run each time. v0.34.0 retries
it.)*

---

## Explicitly non-evidence

Criterion 3 says so, and this record says it back so that no later reader mistakes any of them
for part of the argument above:

- **The `0.x` version number.** wrtag being pre-1.0 is not evidence about this repo's format.
- **The current container's brokenness.** That wrtag is frozen, unrun and pinned to a broken tag
  proves nothing about which tag is correct.
- **The age of the Renovate rule.** The rule was added 2026-06-24 and has been enforcing a broken
  state since; that it is old is not why it is wrong, and that it is old would not make it right.

Everything in this document rests on a rendered path, a captured exit code, a quoted source line
or a published release note.

---

## Every arm wrote nothing — how that was proven

`-dry-run` is safe **in source**: `Move.CanModifyDest()` returns `!dryRun`
(`wrtag.go:766-768`), and `wrtag.go:259` `continue`s on `!op.CanModifyDest()` before line 267's
write. That is a source read, and a source read is not a run. Four independent controls, the last
two asserted **per arm** so a single writing arm would be attributable:

| Control | Mechanism | Result |
|---|---|---|
| Mount layer, source | `-v "$SRC":/music/source:**ro**` | a `move` cannot consume its source whatever `-dry-run` does |
| Mount layer, destination | `-v "$LIB":/music/library:rw` where `$LIB` = `/mnt/fast/spike-03/wrtag-lib`, enforced by a **positive allow-list** in the harness | D-22: the target cannot be the real library. No `/mnt/tank/media` path is mounted in any arm, and the harness contains no reference to one (comment-stripped `grep -c` returns **0**) |
| Instrument 1 | `find "$SRC" "$LIB" -newer <stamp> -type f` | **0 lines**, all 12 arms |
| Instrument 2 | whole-subtree manifest diff — `%p\t%s\t%T@` listing **and** `sha256sum` over every file, both trees, before and after | **empty on all four diffs**, all 12 arms (48 diffs, 0 differences) |

`$LIB` was emptied and asserted empty (`0 entries`) at the start of every arm and was `0 entries`
at the end of every arm. The five-file spot hash used earlier in this phase is **retired**: it
passes a tool that preserves mtimes and it passes any write landing outside the sampled files.
The manifest sees content, size, mtime, additions and deletions across **every** file.

Estate-level, after all twelve arms:

| Assertion | Result |
|---|---|
| `bash scripts/check-music-freeze.sh` | **exit 0** — `tagger-class writers: 0`, `declared rw reaching Music: 0`, `unclassified writers: 0`, `FAILURES total: 0` |
| wrtag containers in `docker ps -a` | **none** — every arm used `--rm` |
| `docker run` hardening | `--rm`, `--security-opt no-new-privileges:true`, no published port, no Traefik label, no added capabilities |
| Frozen files in this plan's diff (D-03) | **none** — `stacks/selfhosted/music/wrtag.yaml`, `stacks/selfhosted/arrs/beets/beets.yaml` and `renovate.json5` all untouched |
| `df -h /` on LXC 100 | 35 G free, unchanged across the plan |

### Attribution of 12 files that changed in the backlog during this run

Recorded rather than glossed, because "pre-existing" is a claim that has to be earned.
`find /mnt/tank/downloads/complete/nzb/music -newermt "2026-09-03 21:05" -type f` returns **12**
— all inside a folder that did not exist when this plan started:
`Taylor Swift - The Life Of A Showgirl-WEB-2025-ALTAiR INT-xpost`, written 21:17:17–21:17:19.

| Fact | Value |
|---|---|
| Files inside either album this plan staged | **0** |
| sabnzbd's beets post-processing log | `import started Thu Sep 3 22:17:20 2026` → `skip /downloads/complete/nzb/music/Taylor Swift - The Life Of A Showgirl-…` (container TZ = 21:17:20 UTC) |
| sabnzbd's mounts | `/mnt/tank/downloads:rw` |
| This plan's mounts on `complete/` | **none at any mode** — the arms mount only `spike-03/wrtag-src:ro` |

The decisive argument is the mount table, not the clock: no container this plan ran held any
handle on `complete/`. This is **DEF-03-01** operating in the open for the second time in this
phase — a live, unattended tagging path running on the exact population Phase 3 samples from,
which `check-music-freeze.sh` structurally cannot see because `sabnzbd` does not match
`TAGGER_PATTERN`.

---

## What wrtag does to tags it did not compute (TAGR-02)

**This is a source-read finding, not a runtime one, and the distinction is not cosmetic.**

A real `wrtag move`/`copy` calls, at `wrtag.go:267` (v0.34.0, verbatim with its guard):

```go
		if !op.CanModifyDest() {
			continue
		}
		if tags.Equal(pt.Tags, destTags) {
			// try to avoid more io if we can
			continue
		}

		if err := tags.WriteTags(destPath, destTags, tags.Clear); err != nil {
```

and `tags.Clear` is `taglib.Clear`, documented at its definition in `sentriz/go-taglib`:

```go
	// Clear indicates that all existing tags not present in the new map should be removed.
```

**So every tag not in wrtag's computed set is wiped unless a `keep` rule is configured. 148 `TKEY`
and 45 `EnergyLevel` files in this corpus are at stake** — the BPM/key metadata that is the entire
point of a DJ collection.

**The dry runs here could not exhibit it**, and say so plainly: `-dry-run` makes
`Move.CanModifyDest()` false, `wrtag.go:259` `continue`s, and line 267 is never reached. Cover
fetching is gated on the same predicate at line 224. Nothing was written and nothing could be.

**And there is a second reason the runtime arms are blind to it, which is worth more than the
first.** `logTagChanges` — the `WRTAG_LOG_LEVEL=debug` output, 588 tag-change lines captured in
arm 1 — iterates `for k := range **after**` (`wrtag.go:1212-1219`). **A tag that exists in the
source and is absent from wrtag's computed set is never logged at all.** It is precisely the
`TKEY`/`EnergyLevel` case, and the most verbose instrument wrtag offers structurally cannot show
it. Arm 1's capture contains **zero** `to=[]` lines, and that is not reassurance — this album
carries no `TKEY` or `EnergyLevel` to lose.

Confirming it empirically needs a **real** `move`/`copy` onto scratch with a `TKEY`-bearing
folder, read back with an independent tag reader. That is not this plan's to run: D-20 holds for
Phases 1–3 and this plan's whole contract is that it writes nothing. **Carried into criterion 4 as
a source-read finding with its provenance stated.** Do not let it harden into "we observed it".

*(One favourable counterpart, also from source and also unconfirmed at runtime: `wrtag metadata
write` calls `tags.WriteTags(path, t, 0)` — flag `0`, not `tags.Clear` — so it **merges**. That is
D-12 row 3b, and it belongs to plan 03-09's bake-off, not here.)*

---

## wrtag's answer for unmatched content

`stacks/selfhosted/music/wrtag.yaml` line 73, verbatim:

```
WRTAG_RESEARCH_LINK=https://www.discogs.com/search/?q={query},https://musicbrainz.org/search?query={query}
```

**Whoever configured that line already knew this content lives on Discogs, and wrtag's answer was
to hand the operator a URL.** Criterion 4 calls that shape of answer a failure: a tagger whose
answer for the content that matters most is *"here is a search page, go and do it yourself"* has
not owned the tree.

Two facts sharpen it, both confirmed in this phase:

- wrtag has **no non-MusicBrainz backend** at v0.20.0 or v0.34.0, and none of v0.30.0–v0.34.0's
  release notes add one (D-12 rows 1 and 2, **HOLDS**). The Discogs link is a *hyperlink*, not an
  integration — wrtag cannot read what it is pointing at.
- `wrtagweb`'s notify-and-confirm queue, genuinely the better import UI (D-12 row 10), can only
  confirm *MusicBrainz* candidates. For the DJ backlog its queue has nothing to offer to confirm.

---

## What this does and does not settle

**Settles:** criterion 3, at three tags and on both disc classes, from runtime and source
together. This repo's `WRTAG_PATH_FORMAT` **does not work on any of the three tags** — it renders
garbage on the one it is pinned to and is refused outright by the two it is pinned away from. The
pin's stated evidence is wrong in four fields and misses both real defects. A one-line change to
the format makes both current tags render correctly and identically.

**Does not settle:** whether wrtag should be retired. That is axis one's verdict and it rests on
D-12 row 1 — *"metadata sources: MusicBrainz only"* — which this plan did not test and which
**HOLDS**. The path format is a bug with a known one-line fix; the source coverage is a
structural property. **Do not let the vividness of `-1 - ` do the work that criterion 1's Discogs
rate is supposed to do.**

**Owned by Phase 4 (TAGR-03), not by this phase:** releasing the Renovate pin, rewriting
`renovate.json5:91`'s description, and choosing a path-format migration. This spike produces the
evidence; D-03 forbids it from acting on it.
