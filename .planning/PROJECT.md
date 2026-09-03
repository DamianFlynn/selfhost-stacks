# Music Library Consolidation

## What This Is

The music tagging pipeline for the Deer Crest selfhost estate. Four tagging entry points were
built over time and three are dead; meanwhile 97 GB of downloaded music sits untagged in
`downloads/complete/nzb/`, against a 34 GB tagged library at `/mnt/tank/media/Music` that
Jellyfin reads. This project picks one tagger, retires the rest, and starts working the backlog
down — beginning with the content that autotags cleanly.

Tracked in GitHub issue #305. Related: #306 (soulbeet), #307 (rybbit).

## Core Value

**New music downloads land in the library correctly tagged, through exactly one pipeline that
someone owns.** Everything else — the historic backlog, the DJ collection, the duplicate
reconciliation — is worth doing but secondary. The reason this project exists is that the
pipeline was built three times and abandoned three times; a fourth half-built path is the one
outcome that must not happen.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] One tagger chosen on evidence from a real sample of this library's content
- [ ] The other taggers retired — definitions removed, Renovate pins released, docs corrected
- [ ] `audio.bash` beets tagging resolved — fixed or turned off, not left silently skipping
- [ ] Known config gaps closed: `match.preferred.countries` for the *Now!* series, `fromfilename`
      and `edit` plugins for DJ content
- [ ] Bucket A (mainstream albums) imported end-to-end and visible in Jellyfin — proof the
      pipeline works before scaling it
- [ ] Bucket D triaged — junk, `_FAILED_`/`_UNPACK_`, stray `.rar`, and misfiled non-music
      (a Harry Potter BluRay rip is currently in `dj-mixes`)
- [ ] The 85 duplicate folder names between `dj-mixes` and `unsorted` investigated and resolved
- [ ] DJ content on its own library path, not mixed into `Compilations/`
- [ ] DJ metadata normalised — field mapping repaired across releases
- [ ] DJ artwork/tracklists sourced for releases that have neither tags nor local scans
- [ ] **Music Assistant reads the same library** — the store mounted from the NUC (HAOS) so the
      tagged tree is playable there, not just in Jellyfin. Phase verification must confirm
      Music Assistant sees the content, not only that files landed on disk.

### Out of Scope

- **Clearing the entire 97 GB backlog** — the goal is a working pipeline plus bucket A proven.
  Buckets B and C become routine work at Damian's own pace, not a project deliverable.
- **Re-importing the existing 34 GB tagged library** — it is already correct and Jellyfin reads
  it. Reconciling the separate beets `library.db` files would mean re-importing one side; treat
  as a known hazard, not a task.
- **Lidarr replacement** — Lidarr stays as the acquisition front end. This project is about what
  happens to files after they land.

## Context

**The four entry points, and why three are dead** (all verified on the host 2026-08-17):

| Entry point | Defined in | State |
|---|---|---|
| `beets` (manual) | `arrs/beets/beets.yaml` | Last import **18 Nov 2025**. `library.db` untouched since. Profile-gated, runs only when invoked. |
| `soulbeet` | `arrs/soulbeet.yaml` | Image `ghcr.io/terry90/soulbeet` **gone from GHCR**. Never deployed. Issue #306. |
| `wrtag` | `music/wrtag.yaml` | Container up, `wrtag.db` unchanged since **23 Jan 2026**. Pinned `<0.30.0` by a Renovate rule blocking a `WRTAG_PATH_FORMAT` rewrite. |
| `audio.bash` beets | sabnzbd post-proc, `music` category | Runs per download, but `rm`s its own `library.blb` each run (stateless by design) and imports `-q` in place. Last two jobs (1 Aug, 8 Aug) both logged `skip`. **Cause now known:** `/config/scripts/beets-config.yaml` declares `plugins: embedart` and nothing else — since beets 2.4.0 MusicBrainz is a plugin, so that config has *no metadata source at all* and every album must skip. Do not "fix" this with `quiet_fallback: asis`. |
| **Lidarr** *(added 2026-08-17)* | `arrs/lidarr.yaml` | **The fifth writer, never counted.** Root folder is `/media/Music` with `renameTracks: True` — it has been actively renaming files inside the shared library tree. |

**The backlog:**

| Location | Files | Size | Tagged? |
|---|---|---|---|
| `downloads/complete/nzb/unsorted` | 7,451 | 97 G | no |
| `downloads/complete/nzb/dj-mixes` | 764 | 25 G | partially — see below |
| `downloads/complete/nzb/music` | 275 | 18 G | no — Lidarr inbox, has `_FAILED_`/`_UNPACK_`/`.rar` |
| `media/Music` (13 artist folders) | 1,244 | 34 G | yes — the Jellyfin source |

*Corrected 2026-08-18 by the Phase 1 measurements.* The `dj-mixes` figure was **794**; that number
counted the 30 JPEG cover scans as tracks and missed the 24 BMPs entirely (`764 audio + 30 jpg =
794`). Real composition: 630 mp3 + 134 wav audio, plus 60 nfo, 30 jpg, 24 bmp, 20 lrc, 1 rtf and a
`.DS_Store`. The **capture scope across all four roots is 9,736 audio files / 170.12 GiB**, not the
~9,764 / ~140 GB assumed — a read ~22% larger than planned, though measured throughput puts it at
roughly 36 minutes because the job is CPU-bound on md5 and single-threaded, not disk-bound.

`media/Music` is 1,244 **audio** files but **2,674 total entries** (87 dirs + 2,586 files), every
one of them at mode **0777**, across five distinct `uid:gid`. That is the real WRIT-04 scope.

**The DJ content is a normalisation problem, not an acquisition problem.** Sampling 8 tracks
across `dj-mixes` found 7 tagged — but with the field convention differing between releases in
the same series:

```
artist="R'n'b Hits 1990-1999 Pt.1 108"  album="VA"                  title="Mastermix_Issue_444 WEB"
artist="Various"                        album="Mastermix Issue 433"  title="Yacht Soul 1 100"
artist="Mastermix Issue 430"            album="Pop Hits 2 119"       title="Mastermix"
```

Trailing numbers are BPM baked into titles, DJ convention. This matters because `beet import -A`
— the approach `beets.md` prescribes for DJ content — preserves existing tags, which would
faithfully preserve the wrong mapping.

**Cover scans exist, but for a minority.** 27 of 85 `dj-mixes` folders contain any image
(54 files total). Where present they carry full tracklistings and are more reliable than any
autotagger. Where absent, artwork and tracklists can be sourced externally — Internet Archive,
or the Mastermix / Music Factory services directly.

**Two consumers, not one.** `/mnt/tank/media/Music` was the Jellyfin source only.
Music Assistant — running on the NUC under Home Assistant OS, a separate box from the Proxmox
host — must read the same store. That makes "tagged correctly" insufficient as a success test:
a phase is only done when the content is visible in **both** Jellyfin and Music Assistant.
*(2026-09-01: the second consumer is live. atlantis serves `/mnt/tank/media/Music` `ro` over NFSv4
to the NUC alone; MA holds 70 albums attributed to the local provider and the three pinned proof
albums exact-match on album name AND album artist. `scripts/check-music-consumers.sh` asserts this
on every `scripts/quick-health-check.sh` run, so the both-consumers test is now a standing check
rather than a one-off.)*

**The mount route is SETTLED — Route A, on measurement** *(resolved 2026-09-01 by Phase 2 plans
02-05 through 02-08; supersedes both the 2026-08-17 "asserted as fact" reading and the "OPEN
QUESTION" reading that replaced it)*. HAOS is a locked-down appliance OS so fstab is out, and the
two candidate routes conflicted between primary sources. **The conflict is resolved, and Music
Assistant's own documentation is the side that is wrong.** MA's docs state verbatim that a folder
cannot be mounted from Home Assistant into `/media`; it is mounted there and readable **from inside
the running Music Assistant container** — `docker exec … ls /media/music` returns the 13 artist
directories. That sentence in MA's docs is about *local* bind mounts, not Supervisor network
storage.

The live route: an HA Supervisor NFS mount named `music` (Settings → System → Storage, usage
**Media**, read-only), `state: active`, `read_only: true`, `user_path: /media/music`, negotiated
`vers=4.2`, propagated `rslave` into the MA add-on container (`master:1105` in
`/proc/self/mountinfo`) — into a container that had started two days before the mount existed. MA
then reads it through a **Local Directory / filesystem** provider, `content_type: music`, instance
`filesystem_local--XJaJWNUS`, pointed at `/media/music`.

**Route B — MA's own "Filesystem (remote share)" NFS provider — was not needed, and its failure
symptom is recorded so this is not re-litigated:** it exposes **no client-side `ro` option at
all** (MA hardcodes its NFS option list), so choosing it would have discarded a whole layer of
defence in depth and left the server-side `ro` as the only guarantee. Route A's mount carries
`ro,relatime,vers=4.2` client-side *and* the export is `ro` server-side.

Both routes needed the same NFS export, so that work was never blocked by the answer.

**Prior art:** `stacks/selfhosted/arrs/beets.md` already documents the library state, the A–D
bucket triage, the two config gaps, and the hard-won gotchas. This project executes and extends
that plan rather than restating it.

## Constraints

- **Storage semantics**: `import.move: yes` is currently set — a bulk run *moves* files out of
  the source rather than copying. First passes must switch to `copy`; `tank` has 9 T free, so
  the duplication is affordable and reversible.
- **Filesystem**: `rsync -a` fails writing to `tank` (`mkstemp ... Operation not permitted`) due
  to `acltype=nfsv4` + `aclmode=restricted` (confirmed on both `tank/media` and `tank/downloads`),
  while printing stats that look like success and exiting 23. Use `rsync -rlt --no-p --no-o --no-g`.
- **Ownership is DECIDED and normalised** *(resolved 2026-08-18 by Phase 1 plan 01-08; supersedes
  the 2026-08-17 "undecided" reading)*: the library is **`568:568` (`apps:apps`)** across all 2,674
  entries, library root included, verified from the Proxmox host and by `zfs diff`. Chosen because
  `568` is `apps` — stated independently in `STANDARDS.md` (§ Volume Mounting), `DEPLOYMENT.md` (§ Storage conventions) and `README.md` (§ Storage)
  and this file — while the gid it replaced, **545, is an orphan**: `getent group 545` returns
  nothing on atlantis. **Modes are the unresolved half: everything is `0777` and stays that way.**
  `chmod` fails `EPERM` on `tank` even as real root, because `aclmode=restricted` +
  `aclinherit=passthrough` gives even new files a non-trivial NFSv4 ACL; the target of `0755`/`0644`
  is recorded but not achieved, and forcing it means `zfs set aclmode=passthrough`, which rewrites
  the ACL on every entry. Phase 2's export inherits `568:568` as `anonuid`/`anongid`, and since ZFS
  `acltype=nfsv4` ACLs are not exported by knfsd, **mode bits are the only lever NFS clients see** —
  so with the tree world-writable the export must be read-only.
  *How the drift happened, kept because it is the signal to watch for:* the earlier reading of
  `apps:nogroup` (`568:65534`) was **LXC 100's view, not the disk**. The container is unprivileged
  with a sparse idmap, so unmapped on-disk ids surface as `65534` — `0:545` and `568:545` both
  collapsed. If `65534` reappears in a container-side listing, check from atlantis before believing
  it. `/mnt/tank/media/TV` still carries 114,218 entries on gid 545 and is deliberately untouched.
- **Jellyfin side effects** *(updated 2026-08-18 by plan 01-06)*: `SaveLocalMetadata`, real-time
  monitoring and `SaveLyricsWithMedia` are now **off for the Music library and permanently so**;
  Movies and TV keep theirs. Still never stage untagged content under `/media/Music`: the freeze
  gates the *automatic* save path only — an explicit "Refresh metadata" (`FullRefresh`) still
  writes, and did rewrite 83 of the library's 91 `.nfo` when tested.
- **Autotagging ceiling** *(corrected 2026-08-17 after research)*: MusicBrainz coverage of these
  labels stops around 2016 (~46 entries: 18 `Mastermix Issue`, 19 `DMC Commercial Collection`,
  9 `Music Factory Mastermix`; `Crate` and `Toolkit` are genuinely zero) and **excludes this
  backlog** — issues 430/433/441/444 all return nothing. Worse, surviving entries are often 5–10
  track *stubs* against 15–20 track releases, so a confident wrong match is more likely than no
  match. **Discogs carries 430, 433 and DMC 350 outright** and is the correct source for this
  content. Never accept a match without a track-count check.
- **Storage layout**: `/mnt/tank/downloads` and `/mnt/tank/media/Music` are **separate ZFS
  datasets**. Every library "move" is copy-then-unlink, not an atomic rename — interruptible, needs
  transient double space, and `cp --reflink` fails `EXDEV` across them despite
  `feature@block_cloning` being active on the pool. Reflink only helps *within* `tank/downloads`,
  which is why staging belongs there.
- **Reversibility**: **beets has no `undo` command** — verified against the live CLI. Backing up the
  `library.db` files is necessary but insufficient — and there are **four** beets databases, not the
  two this document assumed: the manual `beets` one, plus **two under `sabnzbd/`** that nobody
  counted, of which `sabnzbd/config/scripts/library.blb` is the most recently written of the whole
  set (8 Aug 2026). The `soulbeet` database does not exist at all — its data directory is empty.
  Phase 4 is therefore retiring more state than it was scoped for. Take a `zfs snapshot` of `tank/media/Music` in
  the *same step*, because rolling back only the tree leaves `incremental` state claiming the work
  is done. Add the `ffprobe` tag-dump of `dj-mixes` and the cover-scan archive to the same fence.
- **ZFS**: frees space asynchronously; `zfs list` can lag a large delete by ~20 s.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Tagger choice deferred to a spike phase | beets and wrtag both plausible; decide on evidence from a real sample rather than argument | — Pending |
| Done = pipeline fixed + bucket A imported | The failure mode here is abandonment, not slowness. A provable win beats an open-ended import marathon | — Pending |
| DJ content gets its own library path | Keeps `Compilations/` clean for genuine various-artist albums | — Pending |
| DJ metadata: normalise tags *and* extract scans, as separate phases | Tags cover all 85 folders but are misaligned; scans cover 27 folders but are authoritative | — Pending |
| External sourcing for releases with neither | Internet Archive / Music Factory direct, rather than leaving them untagged | — Pending |
| Duplicates investigated before deduping | Sizes differ in both directions across the 85 shared names — neither side is automatically authoritative | — Pending |
| Library ownership normalised to `568:568`; modes stay `0777` | `568` is `apps`, the estate service account named independently in `STANDARDS.md` (§ Volume Mounting), `DEPLOYMENT.md` (§ Storage conventions) and `README.md` (§ Storage); the gid it replaced, 545, is an orphan (`getent group 545` returns nothing). `568:568` also sets the Phase 2 export's `anonuid`/`anongid`. The `0755`/`0644` target is **recorded but not achieved** — `chmod` fails `EPERM` on `tank` even as real root under `aclmode=restricted` | Done 2026-08-18 (01-08 ownership, 01-09 record). Mode half scoped out; export must stay `ro` |
| Jellyfin's Music metadata freeze is permanent | Once one tagger owns the tree, Jellyfin writing metadata into it is a second writer by another name. Nothing to remember to undo. Caveat measured, not assumed: the freeze gates the automatic path only — an explicit `FullRefresh` still writes | Done 2026-08-18 (01-06) |
| Jellyfin retained as the documented sole `rw` holder, not made `:ro` | Consumer-class, frozen at the application layer; going `:ro` risks extracted-subtitle and trickplay behaviour across Movies and TV for no gain while that freeze holds. The audit counts it in its own class so a bare "one writer" cannot read as a pass | Done 2026-08-18 (01-05/01-06). Revisit once the tagger owns the tree |
| **Route A wins: Music Assistant reads the library through an HA Supervisor NFS network-storage mount, not through MA's own remote-share provider** | Chosen on measurement, not on a documentation reading. **The losing route's failure symptom, which is the reason not to revisit it:** MA's "Filesystem (remote share)" provider exposes **no client-side `ro` option at all** — MA hardcodes its NFS option list — so Route B would have discarded a layer of defence in depth and left the server-side `ro` as the sole guarantee. Route A carries `ro,relatime,vers=4.2` client-side *and* `ro` at the export. **MA's own documentation is empirically disproven** on the sentence that drove the whole open question: it states verbatim that a folder cannot be mounted from HA into `/media`, and `docker exec … ls /media/music` inside the running MA add-on returns the 13 artist directories (propagated `rslave`, `master:1105`, into a container that started two days before the mount existed). That sentence is about *local* bind mounts. Measured limit: this is Supervisor's behaviour at the version running on this NUC, proven by `docker exec` and `/proc/self/mountinfo`, not by reading either project's source | Done 2026-09-01 (02-05, re-asserted through 02-08). PROJECT.md's earlier "OPEN QUESTION" passage is corrected above. Accepted consequence (D-27, measured not assumed): `usage: media` also surfaces the library in **Home Assistant's own Media browser**, playable by anyone with HA access — Supervisor offers no finer-grained usage, the mount is `ro`, and the audience already has HA access |
| `missing_album_artist_action: folder_name`, permanently — never MA's `various_artists` default | The target tree is `ALBUMARTIST/Album/NN Title`, so `folder_name` and a correct tag **agree** when the tag is present and **disagree loudly** when it is absent. MA's default is a trap for *this* library specifically: it is heavy on DJ compilations that legitimately *are* Various Artists, so a missing tag would produce an entry indistinguishable from a correct one. Permanent for the same reason the Jellyfin freeze is (row above) — once one tagger owns the tree the path contract is permanent, so a folder/tag disagreement is always a real defect worth surfacing. Nothing to remember to undo. **Measured limit, and it is a large one: the setting is CONDITIONAL.** It fires only when a file's `album` **tag** agrees with its album **folder** name; on a mismatch MA silently uses `Various Artists` **while `config/providers/get` still reads back `folder_name`**. Isolated with a four-cell variant matrix (02-07), not inferred — the track-artist tag is irrelevant. Proven to fire against a deliberate control album *and* 183 times against the real library, so it is working, not merely configured | Done 2026-09-01 (02-06 configured, 02-07 proven to fire). **Carried to Phase 7 as a blocker:** album-tag/album-folder agreement is a precondition to CHECK, not to assume, and reading the setting back is not proof it applies. Live defect found and deliberately **not** repaired: `Def Leppard/Def Leppard (2015)/` derives an EMPTY album artist and hard-errors one FLAC, because the album folder name equals the artist folder name. D-05 forbids tag repair, nobody holds `rw` on Music until Phase 6, and the export is `ro`. `zpool status -v tank` is clean, so it is not scrub damage |
| The export line: `ro,all_squash,anonuid=568,anongid=568,mountpoint,no_subtree_check,sec=sys,root_squash,secure,sync` to `172.16.1.31` alone | `ro` is forced, not chosen: Phase 1 left the tree world-writable at `0777` and ZFS `acltype=nfsv4` ACLs are **not** exported by knfsd, so mode bits are the only lever an NFS client sees (`stacks/selfhosted/arrs/beets.md:215-217`, and the ownership row above). `anonuid`/`anongid` inherit Phase 1's WRIT-04 `568:568`. **`mountpoint` is the single highest-value option and appears in NEITHER of `CLAUDE.md`'s two original candidate option sets** — it makes `rpc.mountd` refuse to serve the export when the ZFS dataset is not mounted, which is the guard against a boot-race where NFS exports an empty directory and MA scans a library that looks deleted. Measured limit, and it corrects three plans of doubt: it was recorded unproven in 02-03 and 02-05 because `exportfs -v` keeps listing the export while the dataset is unmounted. **That observation was right and the inference wrong — the export TABLE is non-discriminating, the SERVED MOUNT is genuinely refused.** Proven by control-probe-control from the NUC: dataset mounted → `exit 0`, 14 entries; unmounted → `exit 255`, `No such file or directory`, 0 entries; remounted → `exit 0`, 14 entries | Done 2026-08-31 (02-03 applied), **M1 PROVEN 2026-09-01 (02-08, commit `a4174e6`)**. Source of truth is `infra/nfs-music-export.tf`; NETWORK.md cross-links it. `M2` (`After=zfs-mount.service` on `nfs-server`) remains the first guard; `mountpoint` is a proven second. Do NOT remove the `mountpoint` option |
| The export is restricted to the NUC's **LAN address `172.16.1.31` only** — the tailnet address is deliberately absent | Traffic the NUC originates toward `172.16.1.158` egresses its LAN interface with source `172.16.1.31` — measured, `ip route get 172.16.1.158` → `src 172.16.1.31`, not taken from `NETWORK.md`. NFS never crosses the tailnet in this design, so adding `100.73.196.51` would widen the blast radius for nothing. Recorded as a decision so it is not re-litigated: if off-LAN mounting is ever wanted, that is a deliberate new export line, not a pre-emptive one. Measured limit: while the NUC is the *standby* subnet router its own LAN IP is unreachable **from a tailnet vantage** (`NETWORK.md:38`, `TAILSCALE.md` §5) — that affects how a human reaches MA's API, and not the NFS path at all, which is LAN-local on both ends | Done 2026-08-31 (02-01 measured, 02-03 applied) |
| **Accepted residual risk: `sec=sys` on a trusted LAN.** Anything that can present as `172.16.1.31` can read the library | Recorded as a **choice, not an oversight or a silence**, so a future security review meets a reasoned answer. Both alternatives were considered and rejected: **`xprtsec=` / RPC-with-TLS (RFC 9289)** needs `tlshd` configured on both ends for a read-only LAN-local music library, and MA itself documents that it adds no encryption or access control and assumes a local network; **`sec=krb5`** means standing up a KDC on this estate for one read-only share, with unproven `sec=krb5` support on the HAOS side. The compensating controls are real and were asserted: single-host client restriction (no wildcard, no CIDR — checked), `all_squash` to `568:568`, `ro` at the export layer, `no_root_squash` forbidden and moot under `all_squash`, and 2049 not port-forwarded. **Criterion 2 was proven at the EXPORT layer, not client-side**: a hand-rolled `mount -o rw` *succeeded* and every write was still refused `EROFS` — re-run over both NFSv3 and NFSv4.2, because a client-side refusal alone would have passed against a writable export | Done 2026-09-01 (02-03 applied, 02-05 proven). Revisit only if the LAN stops being a trust boundary |
| **Accepted residual risk: the Jellyfin API key at `/mnt/fast/secrets/jellyfin-deercrest.env` is ADMINISTRATOR-EQUIVALENT, and phase 02.1 widened its use from read to write** | Recorded as a **choice, not an oversight or a silence**, in the same style as the `sec=sys` row above. The key is admin-equivalent **by Jellyfin's design, not by misconfiguration**: `Jellyfin.Api/Auth/CustomAuthenticationHandler.cs:53-57` maps *any* API key to `UserRoles.Administrator` unconditionally, and **Jellyfin 10.11 has no scoped-key mechanism at all** — so there is nothing to implement and no narrower credential to mint. The key already existed and was already read by `check-music-consumers.sh`; what changed is that 02.1-05 used it to **POST `/System/Configuration/encoding`**. That is a real change in what a leak of that file costs: read access to library metadata becomes write access to server configuration on a service the whole house uses. **ONE COMPENSATING CONTROL WAS WITHDRAWN — named here rather than quietly dropped, because a control list that silently shortens reads as if the item was never there.** This row originally closed with "and Jellyfin publishes no port reachable from outside LXC 100". That was **measured false on 2026-09-03** (plan 02.1-12, artifact `artifacts/02.1-12-reachability-measurement.txt`): `curl http://172.16.1.76:8096/health` returns **200** from the macOS workstation **and** from atlantis, so the admin-equivalent API surface answers across the whole `172.16.1.0/24` and, via the estate's two Tailscale subnet routers, from the tailnet. `172.16.1.76` is the container's `iot_macvlan` LAN address and is the **sole** exposure — the `ports:` mapping is inert (zero listeners on LXC 100, `.NetworkSettings.Ports` all null, `172.16.1.159:8096` refuses from three vantage points). The narrower true fact the false one was generalised from: `172.16.1.76` is unreachable **from LXC 100 itself** under macvlan host isolation. **The three surviving controls were verified and remain true**: mode `600 root`, checked on **every** sourcing by both `check-music-consumers.sh` and `check-jellyfin-transcode.sh`, which **refuse to source the file** on any other mode/owner; the key is passed to curl by **process substitution** so it never enters argv and cannot appear in `ps`; and it is never written to this public repo (screened with a positive control on every plan that touches it). **Residual risk re-derived against LAN-wide reachability. What changed:** the blast radius of a **key leak** is estate-wide rather than confined to a host an attacker must already own — the "must already be on LXC 100 to use it" mitigation does not exist and never did. **What did not change:** reachability of the *endpoint* is not disclosure of the *key* — obtaining it still requires root on LXC 100, asserted on every read. **And what this phase did NOT do:** `172.16.1.76:8096` being LAN-reachable is a **pre-existing estate condition** long predating 02.1; what this phase changed is that the key is now used for **write**, not that the port opened. **Remediation deferred, with its cost named (the same distinction D-22 draws for scheduling — deferred, not overlooked):** dropping `ports:` from `jellyfin.yaml` is near-cosmetic given the measurement; the real lever is detaching **`iot_macvlan`**, which is a **behaviour change** affecting every LAN client and the TV path — an operator was streaming from `172.16.1.76:8096` during the measurement — so it needs its own decision, not a fold-in. Traefik already fronts Jellyfin via the `t3_proxy` service label | Recorded 2026-09-03 (02.1-10); **compensating-control list corrected and risk re-derived 2026-09-03 (02.1-12)**. Revisit if Jellyfin ever ships scoped keys, or if the LAN stops being a trust boundary |
| Phase 02.1's operational detail lives beside the thing it describes, not here | `stacks/selfhosted/media/jellyfin.yaml` carries the transcode retention controls, the ZFS-quota caveat, the "IF THE TV STOPPED" runbook, the **Live TV latent gap** and the volume inventory. The person who needs any of it will be editing the stack file, not reading a music-library planning document | Recorded 2026-09-03 (02.1-10) |
| `scripts/quick-health-check.sh` is **manual-only** and always has been (D-22) | It fires only when someone runs it; scheduling and alerting are deliberately deferred because Phase 2 closed with a notification path that was never proven to deliver. The detail, and the reason, are in-band in that script's third `EXIT-CODE BEHAVIOUR CHANGED` notice — where the person about to trust a green tick will be standing | Recorded 2026-09-03 (02.1-10) |
| Three pieces of Phase 2 runtime state live **only on the NUC** and in no git repository | Stated so a NUC rebuild is a known cost rather than a discovery: (1) Supervisor's `mounts.json` — the `music` NFS mount; (2) **MA's provider settings** — MA 2.11 does not expose a filesystem provider's `path` through its API at all, so the configuration is recoverable only from a SUMMARY; (3) MA's `library.db`. Plus `/config/packages/music02_ma_nfs_mount.yaml` and one `/config/secrets.yaml` key, both reproduced verbatim in `02-08-SUMMARY.md` and in `stacks/selfhosted/arrs/beets.md` — the token excepted, which must be re-minted | Recorded 2026-09-01 (02-06, 02-07, 02-08). Mitigation is the written record, not a backup |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-09-01 after Phase 2 (NFS export and Music Assistant reachability) — the mount
route corrected from OPEN QUESTION to Route A on measurement, and seven Key Decisions recorded.
Operational detail lives beside the stack in `stacks/selfhosted/arrs/beets.md` § "Phase 2".*
