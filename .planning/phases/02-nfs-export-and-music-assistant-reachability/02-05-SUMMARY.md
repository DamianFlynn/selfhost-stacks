---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 05
subsystem: infra
status: complete
tags: [nfs, nfsv4, haos, supervisor-mounts, music-assistant, mount-propagation, cons-01, criterion-2, read-through-hash]

requires:
  - phase: 02-nfs-export-and-music-assistant-reachability
    provides: "02-03's live ro,all_squash export on atlantis (CONS-01 parts 1a/1b/1c); 02-04's three pinned proof albums and the consumers audit script"
  - phase: 01-safety-harness-and-freeze-the-writers
    provides: "the library normalised to 568:568 (WRIT-04), which the export squashes every client identity to; check-music-freeze.sh, the B-8 regression detector"

provides:
  - "ROUTE A WINS, on measurement: a live HAOS Supervisor NFS mount named `music`, state active, read_only true, user_path /media/music"
  - "CONS-01 parts 1d (visible from the NUC) and 1e (NFSv4 negotiated — vers=4.2) proven; CONS-01 is now complete on all five parts"
  - "CRITERION 2 PROVEN AT THE EXPORT LAYER on BOTH protocol versions: a hand-rolled `mount -o rw` succeeds and every write is still refused EROFS"
  - "Read-through sha256 proof for three tracks, 243 MB total, including a 201 MB FLAC and a non-ASCII (U+2019) path"
  - "MA's own documentation is DISPROVEN empirically — /media/music is visible inside the running Music Assistant container, propagated rslave into a container that started 2 days before the mount existed"
  - "D-27 recorded as an accepted consequence, measured not assumed: HA Core reads the same 13 artist directories"
  - "A NEW discriminating instrument for M1 that 02-03 could not have: /proc/fs/nfsd/exports populates once a client mounts"

affects:
  - "02-06 — the provider it creates now has a proven, live /media/music to point at; MA_LOCAL_PROVIDER_INSTANCE is still unset and still 02-06's job"
  - "02-07 — the VA proof album is confirmed unreachable through THIS export; the temporary export is the only route to it"
  - "02-09 — teardown must run B-9's ordering; the client half is now `ha mounts delete music`"

tech-stack:
  added: []
  patterns:
    - "Remote assertion blocks delivered over `ssh host 'bash -s' <<'EOF'` — and NEVER with `ssh -n`, which points stdin at /dev/null and silently eats the heredoc"
    - "Prove the negative twice on different protocol versions: the criterion-2 write refusal was re-run over NFSv3 and NFSv4.2 because the naive `mount -o rw` negotiated v3, not the version MA actually uses"
    - "A dead-man restore (`setsid nohup` + timed re-mount) before opening any window in which a live dataset is unmounted"

key-files:
  created:
    - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-05-SUMMARY.md"
  modified: []

key-decisions:
  - "Route A selected on evidence, not on RESEARCH.md's reading. Route B's failure symptom named: it exposes no client-side `ro` option at all, so it would have discarded the `ro,relatime / vers=4.2` client-side control this mount demonstrably has"
  - "Criterion 2 re-run over NFSv4.2 as well as the v3 the plain `mount -o rw` negotiated — the plan's single test would have proven read-only on a protocol MA does not use"
  - "The third read-through track is a NAMED SUBSTITUTE: the pinned VA album lives under tank/downloads and is structurally outside this export. Substituted with a 201 MB FLAC on a non-ASCII path to buy large-read and path-encoding coverage instead"
  - "The M1 client-side re-test carried from 02-03 was ATTEMPTED and is recorded as still unproven — the sandbox classifier blocked the probe. Not worked around, not silently dropped"
  - "check-music-consumers.sh was copied to LXC 100, run, and removed again — commits 16a9fb2/6d4f8de are local-only, so `git pull` there cannot land it"

patterns-established:
  - "A client-side refusal is never evidence about the server. Every read-only claim in this phase is stated as either client-side or export-layer, never as bare 'read-only'"
  - "Prove container visibility from inside the consuming container, not by arguing from its add-on config"

requirements-completed: [CONS-01]
requirements-carried: [CONS-02, CONS-03]

metrics:
  duration: "~13 min"
  completed: 2026-09-01
  tasks_completed: 3
  tasks_total: 3
---

# Phase 02 Plan 05: Mount the Export, Decide the Route, Prove Criterion 2 Summary

**Route A wins outright, and the strongest evidence against it turned out to be wrong.** Music
Assistant's own documentation states verbatim that a folder cannot be mounted from Home Assistant
into `/media`. It is here, mounted, and readable **from inside the running Music Assistant
container** — a container that started two days before the mount existed and received it by
`rslave` propagation. That is not a documentation reading; it is `docker exec` output.

**Criterion 2 passes at the export layer, twice.** A hand-rolled `mount -o rw` succeeded — which is
what makes the test meaningful — and every write was still refused with `Read-only file system`.
The plan asked for one such test; it was run twice, because the naive command negotiated **NFSv3**
while the Supervisor mount MA actually reads through is **NFSv4.2**. Proving read-only on a
protocol nobody uses would have been the seventh unearned pass.

## Status

| Task | Disposition |
|------|-------------|
| Task 1 — mount, decide Route A vs B | **Complete.** Route A. All five observables asserted, plus the MA-container proof the plan asks for and D-27 measured rather than assumed. |
| Task 2 — criterion 2 at the export layer | **Complete, PASS.** 4a and 4b both captured verbatim; 4b re-run over NFSv4.2. No probe file reached the library. |
| Task 3 — read-through hashes | **Complete.** 3/3 byte-identical, 243 MB total. Third track is a named substitute — reasoning below. |
| *(carried from 02-03)* M1 client-side re-test | **ATTEMPTED, NOT PROVEN.** Window opened and closed safely; the client probe was blocked by the sandbox classifier. New partial evidence recorded. Still open. |

---

## THE ROUTE DECISION — Route A, with Route B's failure symptom named

### Route A, as configured

```
ha mounts add music --type nfs --usage media --server 172.16.1.158 \
    --path /mnt/tank/media/Music --read-only --no-progress
Command completed successfully.
add_exit=0
```

The name is `music`, no hyphen — Supervisor validates against `^[A-Za-z0-9_]+$` and would have
rejected `tank-music` opaquely. The server is the **IP**, so no resolver can redirect it (T-02-08).

### Observable 1 — `ha mounts info --raw-json`, verbatim

```json
{"result":"ok","data":{"default_backup_mount":null,"mounts":[{"path":"/mnt/tank/media/Music","server":"172.16.1.158","name":"music","type":"nfs","usage":"media","read_only":true,"state":"active","user_path":"/media/music"}]}}
```

`state` = `active`, `read_only` = `true`, `user_path` = `/media/music`. All three required.

### Observable 2 — the mount source is the atlantis export, not the emergency stub

```
172.16.1.158:/mnt/tank/media/Music on /media/music type nfs4 (ro,relatime,vers=4.2,rsize=1048576,
wsize=1048576,namlen=255,softerr,softreval,fatal_neterrors=none,proto=tcp,timeo=100,retrans=2,
sec=sys,clientaddr=172.16.1.31,local_lock=none,addr=172.16.1.158)

mount_music_lines=1
emergency_count=0        <-- `mount | grep -c emergency/music`
```

### Observable 3 — the greppable Route-A-failed signal is absent

```
fallback_line_count=0    <-- grep -c 'mounting read-only fallback'
```

Supervisor's own log of the operation, verbatim, with no fallback line anywhere near it:

```
2026-09-01 10:32:32.824 INFO [supervisor.mounts.manager] Creating or updating mount: music
2026-09-01 10:32:32.826 INFO [supervisor.mounts.mount] Creating folder for mount: /data/mounts/music
2026-09-01 10:32:32.984 INFO [supervisor.mounts.mount] Creating folder for mount: /data/media/music
```

### Observable 4 — `ls /media/music` **inside the Music Assistant add-on container**

This is the observable that decides the route, and it was taken the direct way rather than argued
from the add-on's config:

```
$ sudo docker ps | grep music
app_d5369777_music_assistant_beta   ghcr.io/music-assistant/server:2.11.0b0   Up 2 days

$ sudo docker exec app_d5369777_music_assistant_beta ls -la /media/music
drwxrwxrwx 15  568  568   16 Aug 17 10:02 .
-rwxrwxrwx  1  568  568 6148 Oct  1  2025 .DS_Store
drwxrwxrwx  5  568  568   10 Oct 27  2025 BLACKPINK
drwxrwxrwx  3  568  568    6 Oct 27  2025 Benson Boone
drwxrwxrwx  3  568  568    8 Mar 13 03:29 Chris Norman
...
ma_artist_dir_count=13
```

And the MA container's **own** `/proc/self/mountinfo`:

```
1989 2373 0:248 / /media/music ro,relatime master:1105 - nfs4 172.16.1.158:/mnt/tank/media/Music
  ro,vers=4.2,...,clientaddr=172.16.1.31,addr=172.16.1.158

$ sudo docker inspect app_d5369777_music_assistant_beta --format '{{range .Mounts}}...'
/mnt/data/supervisor/media -> /media rw=true prop=rslave
```

**`master:1105` is the whole argument.** The mount inside MA's namespace is a *slave* — it
propagated in from the host. MA has been `Up 2 days`; the mount was created at 10:32 today.
Propagation of a new submount into a long-running add-on container is therefore **proven
empirically**, which is precisely the thing MA's documentation says cannot happen. It can: MA's
sentence is about *local bind* mounts, exactly as RESEARCH.md predicted — but this record rests on
the measurement, not on the prediction.

Ownership reads `568 568` and mode `0777` through the mount, confirming `all_squash,anonuid=568,
anongid=568` is doing what WRIT-04 set it up to do.

### Criterion 1d and 1e

| Criterion | Instrument | Result |
|---|---|---|
| **1d** — the export is visible from the NUC | `showmount` is **ABSENT** on the NUC (measured in 02-01, anti-pattern 4). The substitute is `nc -z -w 5 172.16.1.158 2049` → **exit 0**, and the mount attempt itself, which **succeeded** | **PASS** |
| **1e** — NFSv4 negotiated | `findmnt` is **ABSENT** on the NUC. Read from `/proc/self/mountinfo` instead: fstype column is **`nfs4`**, super-options contain **`vers=4.2`** | **PASS** |

`findmnt` is not "not preferred" here — it does not exist on this host. The plan's `must_haves`
text asking for `findmnt` output is a planning artifact, and `/proc/self/mountinfo` is the
substitute `.continue-here.md` anti-pattern 4 already specified.

### THE LOSING ROUTE'S FAILURE SYMPTOM — Route B

Criterion 5 needs this named while it is in front of us, so:

> **Route B (Music Assistant's own "Filesystem (NFS share)" provider) exposes no `ro` mount option
> at all.** MA hardcodes its NFS option list; there is no place to put `ro`. Route A's mount carries
> a client-side read-only that is visible in three independent places — `read_only: true` in
> `ha mounts info`, `ro,relatime` on the mountinfo line, and `ro` inside the nfs4 super-option
> block. Choosing Route B would have **discarded a working defence in depth** and left the
> server-side `ro` as the single point of failure for the entire library.

That is not a hypothetical. Task 2 below shows the client-side `ro` refusing a write (4a) *and* the
export refusing a write on its own (4b). Route B would have had only the second. The fallback
trigger (D-24) never fired: Route A reached `state: active` on the first attempt, and Task 2's
write attempt **was** refused through the Supervisor mount.

### D-27 — recorded as an accepted consequence, and measured

`usage: media` is what makes Route A work, and Supervisor offers no finer-grained usage. The
consequence is that the library is also browsable in Home Assistant's own Media browser by anyone
with HA access. **Measured rather than assumed:**

```
$ sudo docker exec homeassistant ls -1 /media/music
BLACKPINK / Benson Boone / Chris Norman / Def Leppard / Ed Sheeran ...
hacore_music_entries=13
$ sudo docker exec homeassistant grep ' /media/music ' /proc/self/mountinfo
... ro,relatime master:1105 - nfs4 172.16.1.158:/mnt/tank/media/Music ro,vers=4.2,...
```

**ACCEPTED** (T-02-21). The mount is `ro` on both the client and the export, and the audience is
household members who already have Home Assistant access. Recorded now so it is never discovered
later as a surprise.

---

## TASK 2 — CRITERION 2, PROVEN AT THE EXPORT LAYER

**4b is the criterion. 4a is not.** 4a proves only that the *client* mount is read-only, and would
pass unchanged against a fully writable export. Both are recorded; only 4b is the requirement.

### 4a — through the Supervisor mount (context, NOT the criterion)

```
4a_command=touch /media/music/_ro_probe_4a
4a_stderr=touch: /media/music/_ro_probe_4a: Read-only file system
4a_rc=1

4a_root_stderr=touch: /media/music/_ro_probe_4a_root: Read-only file system
4a_root_rc=1
```

Run as the unprivileged user **and** as root, so "it was only a permissions problem" is ruled out.

### 4b — bypassing the client-side `ro`. THIS IS THE CRITERION.

```
4b_mount_stderr=
4b_mount_rc=0   <-- REQUIRED. A denied mount would be an access-control mismatch (a 02-01
                    measurement error), not a criterion-2 result. The mount was permitted.

--- the probe mount, as the client sees it (note it asked for, and got, rw) ---
2195 2110 0:221 / /tmp/ro_probe rw,relatime - nfs 172.16.1.158:/mnt/tank/media/Music
  rw,vers=3,rsize=1048576,wsize=1048576,...,addr=172.16.1.158

probe_top_entries=14            <-- really mounted, not an empty stub

4b_touch_command=sudo touch /tmp/ro_probe/_ro_probe_test
4b_touch_stderr=touch: /tmp/ro_probe/_ro_probe_test: Read-only file system
4b_touch_rc=1
4b_probe_file_present=no

4b_mkdir_stderr=mkdir: can't create directory '/tmp/ro_probe/_ro_probe_dir': Read-only file system
4b_mkdir_rc=1

umount_rc=0
ro_probe_mount_lines=0
```

**The client's own mountinfo line says `rw`.** The server refused anyway. That is the export
enforcing read-only, which is exactly what CONS-01 criterion 2 asks and what plan 02-03 explicitly
did not claim to have closed. Two different write shapes (`touch`, `mkdir`) were tried so the
result cannot be an artefact of one syscall.

### 4b-v4 — the same test on the version MA actually uses

The plain `mount -o rw` above negotiated **`vers=3`**. The Supervisor mount MA reads through is
**`vers=4.2`**. Proving read-only on NFSv3 alone would leave the operative protocol untested, so
the criterion was re-run:

```
$ sudo mount -t nfs -o rw,vers=4.2 172.16.1.158:/mnt/tank/media/Music /tmp/ro_probe4
4bv4_mount_rc=0
2200 2110 0:335 / /tmp/ro_probe4 rw,relatime - nfs4 172.16.1.158:/mnt/tank/media/Music
  rw,vers=4.2,...,clientaddr=172.16.1.31,addr=172.16.1.158
probe4_top_entries=14

4bv4_touch_stderr=touch: /tmp/ro_probe4/_ro_probe_test_v4: Read-only file system
4bv4_touch_rc=1
4bv4_probe_file_present=no
umount_rc=0
residual_probe_mounts=0
```

**Read-only holds on NFSv3 and NFSv4.2 alike.** Both probe mounts are unmounted; `mount | grep -c
ro_probe` → `0` (T-02-22 closed — a lingering client mount would also block a future `zfs rollback`,
B-9).

### Nothing landed in the library

Asserted on atlantis, not on the client:

```
probe_files_in_library=0          # find -maxdepth 1 -name '_ro_probe*'
any_probe_anywhere=0              # find -name '_ro_probe*' (whole tree)
files_newer_than_task_start=0     # find -newermt '2026-09-01 09:35:29 UTC'
top_level_entries=14              # 13 artist dirs + the historic .DS_Store
```

This is the control that makes T-02-19 real: MA's `check_write_access()` writes a random
`shortuuid` `.txt` at the provider root on **every** provider load. On this export it will raise and
create nothing. 02-06 re-checks after the provider first loads.

---

## TASK 3 — READ-THROUGH HASHES: bytes traverse the mount, intact

**Algorithm: `sha256sum`**, the estate's hash, measured present on both ends in 02-01 (`md5sum` was
the recorded fallback and was not needed).

### The two hashes are different questions — keep them distinct

| Hash | Command | What it proves |
|---|---|---|
| **`audio_md5`** (QUAL-01, from 02-04) | `ffmpeg -map 0:a -c copy -f md5` | *Which recording* the file contains. It is the Phase 1/Phase 7 join key and is deliberately blind to container and tag changes. |
| **plain `sha256`** (this task) | `sha256sum <file>` | The bytes **arrived intact** across the NFS transport. It is deliberately blind to what the audio is. |

### Results — 3/3 byte-identical

| # | Album (02-04 pin) | Track | Bytes | `audio_md5` (names the file) | `sha256` on atlantis == through the mount |
|---|---|---|---|---|---|
| 1 | `Chris Norman/Lifelines (2026)` — single-artist | `Digital Media 01-01 Chris Norman - Lifelines.mp3` | 9,257,839 | `39da9daf74c3a4e2dcc0f35a7612d122` | `01e5f2c0017c74b5c8c0fd12e044661cfe0dda3bd1a3123ddc6cd6cdbd47c4c3` **MATCH** |
| 2 | `Garth Brooks/The Ultimate Hits (2007)` — multi-disc | `CD 01-01 Garth Brooks - Ain't Going Down ('til the Sun Comes Up).flac` | 33,206,242 | `48556eceed2f2cc16709269ee93aa18f` | `342b8e975ec1310ecf5523921ced2a03d11bca3259a074cb7c9a2b3145947314` **MATCH** |
| 3 | `Def Leppard/Adrenalize (1992)` — **named substitute**, see below | `Digital Media 01-01 Def Leppard - Let’s Get Rocked.flac` | 201,088,912 | `239c7599feb7f7e6c7885dedd1af997e` | `a24d03eb59103c5839fa82250b3189dc774b4305703146304f21c8b65697f9d3` **MATCH** |

243,552,993 bytes read end-to-end through the mount. No file was zero-length or missing on either
side; sizes matched exactly, and each was checked with `[ -f ]` and `stat -c %s` before hashing so
a missing or empty file would have been recorded as a failure rather than skipped into a false
match.

Track 1 was additionally hashed **from inside the MA container**, giving the same digest:

```
$ sudo docker exec app_d5369777_music_assistant_beta sh -c 'sha256sum "/media/music/Chris Norman/..."'
01e5f2c0017c74b5c8c0fd12e044661cfe0dda3bd1a3123ddc6cd6cdbd47c4c3
```

### Why track 3 is a substitute, and what the substitute buys

The plan asks for one track from **each** of 02-04's three pinned albums. The third pin,
`VA-Mastermix.Essential.Hits.Pop.4.2005-2009-2025`, lives at
`/mnt/tank/downloads/complete/nzb/unsorted/...` — **outside this export**, which serves
`/mnt/tank/media/Music` only. It is `scope: temp-export` in 02-04's own record and is reachable only
through the D-04/D-15 temporary export that 02-07 stages. It is **structurally** unreachable here,
not missing.

Rather than report 2 of 3, a library album was substituted and chosen to buy transport coverage the
two pins do not:

- **201 MB in a single read** — the largest file in the library after two others; a multi-MB
  streaming read is a different failure mode from a 9 MB one.
- **A non-ASCII path**: `Let’s Get Rocked` carries **U+2019 RIGHT SINGLE QUOTATION MARK**, not an
  ASCII apostrophe. Filename encoding across an NFS boundary is a real and silent failure mode, and
  nothing else in this plan tested it.
- FLAC, matching track 2's container but at 6× the size.

Track 2's path also contains ASCII apostrophes and parentheses (`Ain't Going Down ('til ...)`),
which is incidental but useful.

### This task read only

```
files_newer_than_task_start=0     # find /mnt/tank/media/Music -newermt '2026-09-01 09:35:29 UTC'
total_entries=2674
tank/media/Music  USED 33.9G
```

2,674 entries and 33.9 G, both unchanged from 02-03's measurement.

### Why a library entry in MA would not have been a substitute for this

RESEARCH.md's reboot race step 6 documents the stale state as *"entries exist, playback of any of
them fails"*. An MA library entry can be a survivor from before the mount broke. Only a read
**through** the mount distinguishes a live mount from a stale catalogue, which is why this task is
a hash and not a library query — and deliberately not MA playback, which adds player and codec
failure surface unrelated to the export.

---

## The M1 client-side re-test — ATTEMPTED, STILL UNPROVEN

02-03 recorded, and `STATE.md` carries as a hard item: *"02-05 MUST re-test M1 from the client
side"*. The plan's three tasks do not include it, so this was undertaken as a **Rule 2** addition.
It is reported here rather than quietly dropped.

**What ran.** A dead-man restore (`setsid nohup`, unconditional re-mount at +180 s) was installed on
atlantis first, so the dataset could not be left unmounted by any failure of this session. Then:

```
unmount_exit=0   output=(none)          # zfs unmount tank/media/Music — NO -f, EVER
mounted_now=no
mountpoint_exit_now=32
stub_entries=0

--- exportfs -v, dataset UNMOUNTED (verbatim) ---
/mnt/tank/media/Music
		172.16.1.31(sync,wdelay,hide,...,mountpoint,anonuid=568,anongid=568,sec=sys,ro,...)
music_line_count_while_unmounted=1
```

**02-03's finding reproduces exactly.** The `mountpoint` option does not cause `exportfs` to drop
the line when the dataset is unmounted, on `nfs-utils 1:2.8.3-1`.

**What is new, and it is a genuinely better instrument than 02-03 had.** 02-03 recorded
`/proc/fs/nfsd/exports` as *"non-discriminating — empty in BOTH states"*, correctly noting it is a
client-demand cache and no client had ever mounted. With a live client it **does** populate:

```
# WITH the dataset mounted and a client attached
/mnt/tank/media/Music  172.16.1.31(ro,root_squash,all_squash,sync,wdelay,no_subtree_check,
                                   anonuid=568,anongid=568,uuid=c000d33d:...,sec=1)
/                      172.16.1.31(ro,insecure,no_root_squash,...,v4root,fsid=0,sec=1)
/mnt                   172.16.1.31(ro,insecure,no_root_squash,...,v4root,...)
/mnt/tank              172.16.1.31(ro,insecure,no_root_squash,...,v4root,...)
/mnt/tank/media        172.16.1.31(ro,insecure,no_root_squash,...,v4root,...)

# with the dataset UNMOUNTED
# Version 1.1
# Path Client(Flags) # IPs        <-- header only. The cache emptied.
```

Two things fall out of that, both worth carrying:

1. **`/proc/fs/nfsd/exports` is discriminating once a client exists.** It emptied when the dataset
   went away. That is cache invalidation rather than proof that `rpc.mountd` would *refuse* a fresh
   mount, so it does not close M1 — but the next attempt has a working instrument where 02-03 had
   none.
2. **⚠ The NFSv4 pseudo-root entries carry `no_root_squash`.** `/`, `/mnt`, `/mnt/tank` and
   `/mnt/tank/media` are auto-generated `v4root` traversal entries, are `ro`, and grant traversal
   only — but anyone grepping `/proc/fs/nfsd/exports` for `no_root_squash` will get four hits and
   reasonably read it as a T-02-06 regression. `check-music-consumers.sh` is unaffected: it parses
   `exportfs -v`, where the count is correctly `0`. **Recorded so nobody re-points that assertion at
   the kernel table.**

**Why it is not proven.** The definitive step — a *fresh* client `mount` attempt while the dataset
is unmounted, to see whether `rpc.mountd` refuses it — was **blocked by the sandbox permission
classifier**, twice. Per the operating rules that denial was not worked around.

**The estate was restored immediately and verified, not left to the dead-man:**

```
mount_exit=0   mounted=yes
exportfs_ra_exit=0
/mnt/tank/media/Music
		172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
top_entries=14      mountpoint_after_restore=0
nfs-server: active / enabled
```

Client side after the window, unharmed — the mount is `softerr`, so it returned errors rather than
hanging, and recovered without a reload:

```
ls -A /media/music | wc -l       -> 14
ha mounts info                   -> state active, read_only true, user_path /media/music
MA container ls -1 /media/music  -> 13
stale probe mounts               -> 0
```

The dead-man helper was removed afterwards (`/root/m1-deadman.sh` — gone).

**M1 remains `configured-but-UNPROVEN`, and the threat flag 02-03 raised against
`infra/nfs-music-export.tf` stands.** M2 (`After=zfs-mount.service`) is still the proven guard, and
the residual exposure is still narrow: a stale or empty MA library, never data loss, because the
export is `ro` — which this plan has now proven at the export layer.

---

## Wave gate

Run before closing, so a Phase 1 regression cannot hide behind a Phase 2 pass.

### `check-music-consumers.sh --baseline` → exit **0**

```
  MA version (live):           2.11.0b0   (assertions proven at 2.11.0b0)   <-- no drift
  export route:                ssh:172.16.1.158
  ma route:                    http://172.16.1.31:8095
  jellyfin route:              docker-inspect:192.168.90.25:8096
  ha route:                    skipped   (expected on LXC 100 — see header)
  pinned provider instance:    <UNPINNED — set by plan 02-06>
  albums matched in Jellyfin:  2   (target 2, exact name+albumartist)
  jellyfin out-of-scope:       1   (scope!=library — reported, not asserted)
  export assertions failed:    0     <-- SECTION 1 GREEN, 10/10
  MA assertions failed:        5     <-- by design; 02-06 owns MA_LOCAL_PROVIDER_INSTANCE
  Jellyfin assertions failed:  0
  FAILURES total:              5
```

The five MA failures are the single root cause 02-04 designed in: the local filesystem provider does
not exist yet, so the script refuses to credit any album match to an export it cannot prove the
match came through. **Do not "fix" this** — 02-06 owns it. `MA_LOCAL_PROVIDER_INSTANCE` is
deliberately still unset by this plan, because this plan created no provider.

### `check-music-freeze.sh` → exit **0**

```
  tagger-class writers:        0   (target 0)
  unclassified writers:        0   (target 0)
  declared rw reaching Music:  0   (target 0, jellyfin.yaml excluded)
  ownership mismatches:        0   (target 0, want 568:568)
  artist folders:              13
  sidecars found (widened):    1341   (nfo 91 / jpg 88 / lrc 944 / png 43 / txt 175)
  sidecars found (narrow D-18):1123
  fence assertions failed:     0
  FAILURES total:              0
✅ Music freeze harness intact
```

Identical to 01-09's closure and to 02-03's after-state. Adding an NFS *reader* changed no inode,
and the measurement agrees with the argument.

### Host health, after the plan

```
uptime -s                                    2026-08-31 18:48:08   (unmoved — no crash)
/proc/pressure/io  full avg300               0.18                  (halt was 96.22)
dmesg | grep -c amdgpu_hmm_invalidate_gfx    0
```

---

## Deviations from Plan

### 1. [Rule 3 — Blocking] `172.16.1.31` is unreachable from this vantage; the tailnet address was used

- **Found during:** Task 1 setup.
- **Issue:** Every command in the plan's `<verify>` blocks resolves the NUC as `$HA_SSH_HOST` =
  `172.16.1.31`. This session runs from a **tailnet** vantage, and the NUC is currently the
  **standby** subnet router for `172.16.1.0/24` — so its own LAN IP is unreachable from the tailnet
  (replies egress `tailscale0` sourced from an IP outside the peer's AllowedIPs and WireGuard drops
  them). This is documented in the `ha-deercrest` skill and the `tailnet-lan-redundancy` memory.
- **Fix:** All NUC access used `$HA_TAILNET_HOST` (`100.73.196.51`). atlantis (`172.16.1.158`) and
  LXC 100 (`172.16.1.159`) are reachable normally via the gateway's subnet route and were used
  as-is.
- **Not a defect in the estate** — it self-heals if HA is promoted to primary. Named here so the
  next executor does not read a connection timeout as a mount failure.

### 2. [Rule 3 — Blocking] `ssh -n` eats a heredoc

- **Found during:** Task 2 setup — an atlantis assertion block returned a header line and nothing
  else.
- **Issue:** `.continue-here.md` mandates `ssh -n` (correctly — a nested `ssh` otherwise consumes
  the outer script's stdin). But `-n` redirects stdin from `/dev/null`, so
  `ssh -n host 'bash -s' <<'EOF'` silently discards **the entire script** and exits 0. A block of
  assertions returning nothing is indistinguishable from a block of assertions all passing quietly.
- **Fix:** The rule is now stated precisely: **use `-n` for inline `ssh host 'cmd'` invocations;
  never use `-n` when feeding a script over stdin with `bash -s`.** Both forms are used in this
  plan, each in its correct place.
- **Same family as 02-03's deviation 3** — a quoting/redirection error that manufactures silent
  passes. Third occurrence in this phase.

### 3. [Rule 2 — Missing critical coverage] Criterion 2 re-run over NFSv4.2

- **Found during:** Task 2, reading the probe's own mountinfo line.
- **Issue:** The plan's 4b command is `mount -t nfs -o rw ...` with no version. It negotiated
  **`vers=3`**. The Supervisor mount MA reads through is **`vers=4.2`**. NFSv3 and NFSv4 take
  entirely different paths through `rpc.mountd`/`nfsd`, so a read-only result on one is not evidence
  about the other. Left as written, criterion 2 would have been proven on a protocol nothing in this
  estate uses.
- **Fix:** Added `4b-v4`, an explicit `-o rw,vers=4.2` probe. Both refuse writes. The stronger claim
  is now supported: read-only is enforced on **both** protocol versions this export answers on.
- **Files modified:** none.

### 4. [Rule 2 — Named substitution] Read-through track 3

The pinned VA album is outside this export by design. Substituted with a 201 MB FLAC on a
non-ASCII path, with the reasoning, the coverage gained, and the owner of the real proof (02-07's
temporary export) all stated under Task 3. Not silently dropped, not counted as a pin.

### 5. [Rule 2 — carried obligation] The M1 client-side re-test was attempted

`STATE.md` carries it as a MUST for 02-05 and the plan's task list omits it. Attempted, partially
advanced, blocked, restored, and reported in full above. **Still open.**

### Not fixed — logged, out of scope

- **`check-music-consumers.sh` is still not on LXC 100, and `git pull` there cannot land it.**
  `.continue-here.md` says to pull before running it. The pull ran and brought LXC 100 to
  `aa2b502` — but commits `16a9fb2` (the script) and `6d4f8de` are **local-only on the workstation
  and not pushed to origin**. The script was therefore `scp`'d in, run for the wave gate, and
  removed again (02-04's own practice, so a future pull lands the tracked copy cleanly). Verified
  absent afterwards. **02-06 or 02-09 must push before relying on a pull.**
- **This working tree has diverged from origin: `ahead 33, behind 9`.** Origin carries 9 commits
  this checkout lacks, including `.planning/phases/03-tagger-spike/03-CONTEXT.md`. Pre-existing and
  unrelated to this plan; not reconciled here.
- Two pre-existing untracked files on LXC 100 (`prometheus.yaml.bak`,
  `monitoring.app.yaml.disabled`), unchanged since 02-04 noted them.
- The untracked `body.txt` at repo root, left alone as in 02-03 and 02-04.

## Authentication gates

None. The HA SSH key and `sudo` (NOPASSWD) were both already provisioned; the `ha` CLI needed the
documented `bash -lc` login-shell wrapper and worked first time.

---

## Requirements

**CONS-01 is now COMPLETE and is ticked.** 02-03 deliberately left it open because criterion 1 has
five separately-falsifiable parts and it could only close 1a, 1b and 1c without a client. This plan
supplies the client and closes the remaining two:

| Part | Owner | Evidence |
|---|---|---|
| 1a — export is correct | 02-03 | `exportfs -v`: `ro,all_squash,anonuid=568,anongid=568,mountpoint`, single client `172.16.1.31` |
| 1b — clean re-apply | 02-03 | `terraform plan` exit 0, `No changes.` |
| 1c — served from the host, not LXC 100 | 02-03 | `nfs-server` absent and impossible in the unprivileged container |
| **1d — visible from the NUC** | **02-05** | **`nc` 2049 exit 0; the mount succeeded and reads 13 artist directories** |
| **1e — NFSv4 negotiated** | **02-05** | **`/proc/self/mountinfo` fstype `nfs4`, `vers=4.2`** |
| **criterion 2 — read-only at the export** | **02-05** | **`touch` EROFS despite `-o rw`, on v3 and v4.2** |

CONS-02 and CONS-03 stay **Pending** — both need the local filesystem provider, which is 02-06's.
The instrument reports them as 5 open failures, which is the correct state, not breakage.

## Threat Register Status

| Threat ID | Disposition | Status after this plan |
|-----------|-------------|------------------------|
| T-02-03 | mitigate | **CLOSED — this is the plan's headline.** A hand-rolled `rw` mount succeeded and every write was refused EROFS, on NFSv3 and NFSv4.2. The gap 02-03 explicitly did not claim to close is closed. |
| T-02-19 | mitigate | **Server side closed.** The export refuses `check_write_access()`'s `shortuuid` `.txt` by construction; `_ro_probe*` count in the library is `0`. 02-06 re-checks after the provider first loads. |
| T-02-20 | mitigate | **Closed, and the two cases never conflated.** The probe *mount* succeeded (rc 0) — so the NUC's source address matches the export line and 02-01 Task 3's `src 172.16.1.31` measurement is confirmed correct. The refusal was on the *write*, which is criterion 2 passing. |
| T-02-22 | mitigate | **Closed.** Both probe mounts unmounted in the same command; `mount \| grep -c ro_probe` → `0`; `/tmp/ro_probe`, `/tmp/ro_probe4` removed. No client mount can block a future `zfs rollback`. |
| T-02-23 | mitigate | **Closed on three independent instruments.** `/media/music` was absent and `ha mounts info` empty before mounting (D-26); the mount source is the atlantis export with `emergency_count=0`; `mounting read-only fallback` count `0`; and Task 3's read-through hashes are the second instrument, which an emergency empty-directory bind could not produce. |
| T-02-21 | accept | **Recorded, not discovered later.** HA Core reads the same 13 directories — measured, above. `usage: media` is what makes Route A work; the mount is `ro`; the audience already has HA access. Also belongs in PROJECT.md per D-47. |
| T-02-08 | mitigate | **Held.** The server was given as an IP in the Supervisor mount, so no resolver can redirect it. The export still names one LAN address and the tailnet address is still absent (D-13). |
| T-02-06 | mitigate | **Held on `exportfs -v` (count 0)** — see the pseudo-root caveat under M1 above before re-pointing this assertion at `/proc/fs/nfsd/exports`. |

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: misleading-instrument | `/proc/fs/nfsd/exports` (kernel table, no repo file) | Once a client mounts, the NFSv4 pseudo-root entries for `/`, `/mnt`, `/mnt/tank` and `/mnt/tank/media` appear carrying `no_root_squash`. They are `v4root` traversal-only entries and `ro`, and they are **not** a T-02-06 regression — but a `grep -c no_root_squash` against this table returns `4`. Any future check must parse `exportfs -v`, as `check-music-consumers.sh` already does. |

*(02-03's `threat_flag: control-not-enforced` on `infra/nfs-music-export.tf` is **not** cleared —
see the M1 section.)*

## Known Stubs

None. The mount is live, proven, and read from by the Music Assistant container. It has no provider
pointed at it yet, which is 02-06's work and D-52's intended increment shape, not a stub.

## Self-Check

Files claimed created/modified:

- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-05-SUMMARY.md` — FOUND

Commits: Tasks 1, 2 and 3 all declare `<files>none in-repo</files>` — they mount, assert and hash,
and change nothing in the repository. They therefore produce **no source commits**, matching the
02-03 (Tasks 2/3) and 02-04 (Tasks 1/2) precedent. Their record rides with this SUMMARY. Stated
explicitly so the absence is not read as skipped work.

Live state re-verified at close:

- `ha mounts info` → `music`, `state: active`, `read_only: true`, `user_path: /media/music` — FOUND
- `/media/music` inside `app_d5369777_music_assistant_beta` → 13 artist directories — FOUND
- `mount | grep -c ro_probe` on the NUC → `0` — no residual probe mounts
- `find /mnt/tank/media/Music -name '_ro_probe*'` on atlantis → `0` — no probe file in the library
- `find /mnt/tank/media/Music -newermt '2026-09-01 09:35:29 UTC'` → `0` — nothing written
- `tank/media/Music` → 2,674 entries, 33.9 G, `mounted=yes`, exported, `nfs-server` active + enabled
- `/root/m1-deadman.sh` on atlantis → removed
- `scripts/check-music-consumers.sh` on LXC 100 → removed after the wave gate

## Self-Check: PASSED
