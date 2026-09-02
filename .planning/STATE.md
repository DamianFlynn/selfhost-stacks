---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-09-02T22:35:00.000Z"
last_activity: 2026-09-02 — 02.1-05 complete (THE CUTOVER — the container recreated onto the
  declared binds, and Jellyfin's five retention settings applied by read-modify-write)
progress:
  total_phases: 10
  completed_phases: 2
  total_plans: 39
  completed_plans: 24
  percent: 20
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-17)

**Core value:** New music downloads land in the library correctly tagged, through exactly one
pipeline that someone owns.
**Current focus:** Phase 02.1 — jellyfin-transcode-retention-relocate-the-anonymous-transcod

**Definition of done (CONS-04):** a file is imported only when verified with `ffprobe` on the file
*and* visible in both Jellyfin and Music Assistant. Never "tool configured".

## Current Position

Phase: 02.1 (jellyfin-transcode-retention-relocate-the-anonymous-transcod) — EXECUTING
Plan: 6 of 10
Status: EXECUTING — **02.1-05 COMPLETE. THE CUTOVER IS DONE.** At **2026-09-02T22:19:52Z** Jellyfin
stopped writing its cache to `/`. The container was recreated onto the binds 02.1-04 declared, and
the mount shape is now proven on the **runtime** rather than in the file: **zero `Type: volume`
mounts** (D-18's invariant, asserted before the container was even enumerated), `/cache/transcodes`
→ `bind /mnt/fast/transcode`, `/cache` → `bind /mnt/fast/appdata/media/jellyfin/cache`, and
`/data/transcode` in **no** destination. **Assumption A4 is CONFIRMED by probe, not by reading
moby's sort**: a file written into `/cache/transcodes` from *inside* the container appeared at
`/mnt/fast/transcode/` and **not** under the cache bind. Jellyfin then wrote its own
`.jellyfin-transcode` marker into the dataset at 22:20Z — the *server* agreeing, not just the daemon.

**Jellyfin's five retention values are live**, applied by strict read-modify-write (POST returned
204, no restart): `TranscodingTempPath=/cache/transcodes`, `EnableSegmentDeletion=true`,
`SegmentKeepSeconds` 720→**300**, `EnableThrottling=true`, `ThrottleDelaySeconds=180`. **The amdgpu
mitigation SURVIVED** — `HardwareAccelerationType=none` and `EnableHardwareEncoding=false`, asserted
against both the captured pre-write values and the literals. That endpoint is a **full-object
replace** and `EnableHardwareEncoding`'s constructor default is **true**, so a partial POST would
have silently re-armed the hazard that cost ~6 hours on 2026-08-31.

**The ZFS bound did not notice the container being destroyed and rebuilt** — `quota=53687091200`,
`mounted=yes`, both re-read from atlantis *after* the recreate (VALIDATION rows 10 and 36). That is
exactly why D-12 makes the ZFS property load-bearing rather than an application setting.

**Standing check: `FAILURES total: 5` → `1`.** The one remaining red is section 3, *"the anonymous
volume STILL EXISTS"*, and it is **supposed** to be red here. **The volume was deliberately NOT
deleted** — it is the rollback, D-10 keeps it until the thing it protects is proven, and it is
proven now. **02.1-06 may proceed**, and it is what releases the 12.55 GiB still sitting on `/`.

**⚠ VALIDATION.md row 15 IS WRONG AS WRITTEN and needs correcting before 02.1-10 verifies against
it.** It asserts the changed-key set equals five names *including* `ThrottleDelaySeconds` — but that
value was already `180`, so setting it to `180` changed nothing, and the equality was unsatisfiable
from the moment it was written. The plan's own prose, 02.1-RESEARCH.md and `jellyfin.yaml` all say
`180 -> 180 UNCHANGED`. **This was NOT the full-object-replace hazard firing**: the hazard is the
*superset* direction and it was measured directly — `changed_keys − intended_five` = `[]`.

**Two numbers 02.1-04 discovered that the plan set did not have.** (1) The old volume's
`transcodes/` is **12.55 GiB across 1,324 files**, not the 472 K the plans assume — so it was
EXCLUDED from the copy (shadowed by the nested bind, deleted in 02.1-06, and copying it would
breach the headroom precondition outright). (2) **`rsync` is NOT INSTALLED on LXC 100** and was
deliberately not installed; the documented `cp` equivalence was used. Assumption **A5 is
CONFIRMED** — `cp --preserve=all` succeeds on `fast/appdata/media` (`nfsv4` + `passthrough`), so
the `tank` EPERM failure mode does not apply there.

Before that, 02.1-03 completed: `fast/transcode` is **declared** in `infra/` Terraform
(`infra/jellyfin-transcode-dataset.tf`, `var.jellyfin_transcode_quota`) and carries
**`quota=53687091200`** live, with `compression=off`, `sync=disabled`, `recordsize=1048576`,
`atime=off`, `mounted=yes` and `2775 apps:apps` — all read back from atlantis, not from Terraform's
own output. **TRAN-07 is COMPLETE**; TRAN-03 stays Pending because it requires the bound proven
**firing** (02.1-08), not proven set.

**⚠ BOTH OF 02.1-02's OPEN QUESTIONS ARE NOW RULED — do not re-litigate either.**
(1) The `/` **ORDERING** question: the reap **stays in 02.1-09**, 02.1-03 proceeded. Basis, measured
not assumed: every write in 02.1-03 lands on the `fast` pool (`stat -c %d` → `/mnt/fast/transcode` =
47, `/` and `/mnt/fast` both 64519) and none on `/`; the post-apply `/` reading of 20.16 GiB confirms
it. **The ruling covered 02.1-03 ONLY** — 02.1-04 (copy) and 02.1-05 (recreate) *do* touch `/` and
must be re-ruled on their own numbers against a **0.16 GiB** margin.
**02.1-04 HAS SINCE BEEN RE-RULED — by the EXECUTE-PHASE ORCHESTRATOR, not by the operator.** Weigh
it as an agent's ruling, not a human's: the D-17 floor is a conservative *policy* tripwire, not a
physical limit, actually-free is ~20.16 GiB, and the budget granted was numeric — halt if a step
would cost >2 GiB of `/`, if `/` actually-free would fall below 10 GiB, or if the transcode cache
resumed growing. **None fired, and the copy measured `/`-NEUTRAL (+14.0 MiB)** because source
(dev 64519, ext4) and destination (dev 63, zfs) are different filesystems.
**02.1-05 WAS RE-RULED IN TURN — again by the ORCHESTRATOR, not the operator** — on the same numeric
terms plus one addition specific to a recreate: **check image residency first**, because a pull is a
1.45 GiB write into `/var/lib/docker` on `/` and is the one genuine multi-GB consumer a compose
change has available. The image was already resident (digest `d57d4a0c…`, identical either side), so
**no pull occurred**. **Nothing fired and the recreate was `/`-POSITIVE: +37 MiB**, the old
container's writable layer released and not fully replaced. **The margin is now ~216 MiB, the widest
it has been all phase.** That ruling covers **02.1-05 ONLY**; 02.1-06 is the `docker volume rm`, a
different shape again — it *releases* 12.55 GiB rather than spending anything — and gets its own
numbers.
(2) The **TERRAFORM** question, which 02.1-03 halted on separately: the baseline
`terraform plan -detailed-exitcode` exited **2**, not 0, tripping VALIDATION row 28. The drift was
output-only (`verify_commands`, a stale heredoc from `76b3783`; non-no-op `resource_changes` measured
`count 0 / destroys 0 / addresses []`). **The operator ruled OPTION B** — clear it as its own
separate guarded apply first, then execute against a genuinely clean exit-0 baseline — because row 28
is a row this phase gets verified against and only B satisfies it *literally*. Executed as **two
applies**, each from its own saved workstation-local plan file, each mechanically asserted before it
ran. **`infra/` now has a clean exit-0 baseline**, so the next saved-plan assertion there contains
only its own change.

Before that, 02.1-01 landed the TRAN ids, cleared the
ROADMAP placeholders and opened the D-32 watch (still
open). Phase 02.1 was **replanned against cross-AI review**: 10 plans in 9 waves,
plan-checker passed with 0 blockers. 32 locked decisions (D-01…D-32, of which **D-29/D-30 were ruled
by the operator during plan-phase** and **D-31/D-32 during the review replan**; all four postdate
RESEARCH.md), 9 requirements TRAN-01…TRAN-09, and a 38-row VALIDATION.md contract that separates
**read-back** from **fires** — rows must be discharged by a real observation, never by reading a
setting back (CONS-04). **D-31 re-ordered the waves so the cutover is the critical path**: `/` is
structurally protected at the end of wave 6 of 9, not wave 4 of 5 behind a blocking human gate.
(Wave count went 8 → 9 in **review round 2**, when Codex — the first genuinely non-Anthropic
reviewer of this phase, its install having been repaired — raised four HIGH findings none of the
round-1 reviewers surfaced. Three were verified real against the plan text: a verification that
re-ran the destructive image prune, a playback transcript that would have committed the Jellyfin
API key into this **public** repo, and a quota restore written as prose with no `trap`. The fourth
reversed a round-1 decline and encoded `02.1-02`'s dependency on `02.1-01`, cascading every later
wave +1.)

**Phase 03 remains planned from 2026-09-01** — 11 plans, 8 waves, plan-checker passed,
then **cross-AI reviewed (codex / gh copilot / gemini) and revised against 13 findings**, and passed
the checker again clean. Research falsified parts of CONTEXT.md and six operator decisions (OD-1…OD-6)
now override it where they conflict; they are recorded in the plan set and must be carried into
execution.

**Wave 1's disk gate is CLEARED, but its premise was wrong — carry this into phase 2.1.** 03-01
completed 2026-09-02: the operator-approved 27-image reap ran with 0 `rmi` failures and reclaimed its
full 18 GiB estimate. But images were never the real lever. While 03-01 sat at its approval gate `/`
went from 2.2 GB free to **zero**, and measurement found the consumer was a **19 GB Jellyfin
transcode cache** in an *anonymous* Docker volume (`d98b2ff9…/_data/transcodes`) — larger than the
entire image reap, and unlike images it **refills**. No `ffmpeg` was running, so this is cache
retention, not the documented amdgpu/VAAPI orphan hazard. Clearing it plus the reap took `/` to
**36 GiB free** against the 8 GiB floor (34 GiB after the four spike pulls, so OD-1's A2 estimate of
2.0–2.3 GB holds). `docker system df` still reports ~62 GB reclaimable across images, so the audited
27 were always the conservative subset. **Phase 2.1 is inserted to fix the retention durably** — the
volume being anonymous rather than a declared bind mount to `/mnt/fast` is the root cause.

**⚠ Two review findings changed how the headline number is computed — carry these into execution:**

- **The 24-folder sample is a COVERAGE sample, not a population estimate.** It is stratified and
  deliberately never random. T1's headline strict rate and T2's extrapolation are therefore a
  **per-stratum roll-up weighted by each stratum's prevalence across the 143-folder backlog**
  (`Σ_s rate_s × weight_s`), never an unweighted average over the 24. The unweighted figure is
  reported beside it and is explicitly *not* what T1 is tested against. **The 40% threshold value is
  unchanged** — only the estimator was specified, and it was specified before any weight or rate
  existed, which is why criterion 5 survives. A stratum with backlog weight but no sampled folder is
  a **named hole**, enters the roll-up with a 0%/100% band, and if that band straddles 40% **T1 is
  recorded `indeterminate`** rather than resolved by picking an end.

- **Criterion 5's custody is a pushed commit, not local history.** 03-02 must reach `origin` before
  any evidence plan starts, and 03-07 re-asserts the SHA is reachable from `origin/main` before it
  measures anything. `git log -p` on a mutable local branch is evidence, not proof.

**Operator decisions taken at review:** the weighted roll-up (not a second random sample); and the
spike compose configs are **archived** under `.planning/` with a `THROWAWAY — DO NOT DEPLOY` banner
rather than deleted — containers and every credential-bearing runtime file are still purged.

**Phase 02 CLOSED 2026-09-01** — all nine plans executed, all five criteria
proven, CONS-01/02/03 complete, verification `passed` 5/5. The consumers audit is folded into
`quick-health-check.sh`, criterion 5 is recorded in
PROJECT.md with Route B's failure symptom and the old assertion rewritten, and the operational record
is in `beets.md` and `NETWORK.md`. **D-55's human gate is SATISFIED** — and by a stronger test than
it asked for: the operator browsed MA's Filesystem (local disk) provider, spot-checked albums, and
**played tracks to confirm the audio matches the metadata**. No assertion in this phase could do
that — every automated check verifies MA's *database* says the right thing, never that the *bytes*
are the right song, and the documented stale state is precisely "entries exist, playback fails".
Last activity: 2026-09-02 — 02.1-05 complete (**THE CUTOVER** — the container recreated onto the
declared binds at 22:19:52Z, assumption A4 confirmed by write-through probe, the quota and mount
proven to survive the recreate, and the five encoding settings applied by read-modify-write with the
amdgpu mitigation asserted intact). Before that, 02.1-04 completed (the cache copy and the compose
declaration; finished
by a continuation agent after the first executor was killed by a transient API error mid-plan, with
every assertion re-derived from live state rather than inherited). Before that, 02.1-03 completed
(the dataset declaration and the quota; two guarded
applies, A3 confirmed byte-exact). Before that, 02.1-02 completed (the standing transcode check and
its baseline), and before
that, 02.1-01 completed, and before that 02.1 was replanned against
cross-AI review in **two rounds**
(`/gsd-review` → `/gsd-plan-phase --reviews`): 9 plans in 5 waves became 10 in 8, then 10 in **9**
after round 2. **Round-2 plan-checker pass completed 2026-09-02 against commit `2755734`: 0
blockers, 3 warnings, all three fixed.**
**Round 1** — Gemini + Claude; **Codex could not run** (missing `@openai/codex-darwin-arm64`), so
Gemini was the sole cross-family reviewer. All 26 findings applied or reframed with a stated reason,
none rebutted. The two proofs that **could not fail** are repaired:
`disable-jellyfin-hwaccel.sh` gained a standalone `verify-retention` sub-action and a `TRAN09_FAULT=1`
gate, and the segment-deletion proof now drives a real HLS client whose download head must advance.
The 49.5 GB ballast became a temporary `quota=1G` shrink with `conv=fsync` and a bounded retry.
**Round 2** — the operator repaired the Codex install, and Codex reviewed the *revised* ten-plan set
(the first genuinely non-Anthropic review of this phase). It raised **four HIGH findings neither
round-1 reviewer surfaced**, three verified real against the plan text: `02.1-09`'s verification
**re-ran the destructive prune** it was meant to verify; `02.1-06` would have committed the Jellyfin
**API key** into this **public** repo, because Jellyfin embeds `api_key=` in `TranscodingUrl`; and the
`quota=50G` restore was **prose, not a `trap`**, so an aborted run left the dataset at `quota=1G` —
which takes the TV down on the next play. The fourth **reversed a round-1 decline**: `02.1-02`'s
dependency on `02.1-01` was unencoded, and `parallelization: false` is mutable executor config, not
dependency semantics. Encoding it cascaded 8 waves → 9 and D-31's descriptive wave number was
corrected (its substance — cutover first — is unchanged). Codex was also **wrong once**: it argued a
lost-append race on the D-32 watch because `02.1-07`/`08` share a wave, but neither writes to it —
the eight writers are each alone in their wave. **Standing lesson: three of the four HIGH findings
were plainly present in the plan text and no Anthropic-family reviewer saw them. Single-family
review understates its own blind spot; verify every finding against the text rather than counting
reviewers.**
Research characterised the incident from Jellyfin's own source at the running tag (`v10.11.11`) and
found the transcode was a **stream-copy remux** of an 18 GB / 17.93 Mbit/s source — one unbounded
orphan accounts for the whole 19 GB. Two operator rulings were taken mid-planning: **D-29** hardens
`scripts/disable-jellyfin-hwaccel.sh`, whose `do_enable` restores the whole `encoding.xml` from a
`.bak` predating this phase and would otherwise be a one-command silent revert of everything 02.1
installs; **D-30** preserves `HardwareAccelerationType: none` / `EnableHardwareEncoding: false` (the
2026-08-31 amdgpu mitigation) verbatim and asserts them after the write, because the encoding REST
endpoint is a **full-object replace**.

Prior activity: 2026-09-02 — Phase 03 execution started; 03-01 complete (disk-headroom gate cleared,
36 GiB free). Phase 03 **halted after 03-01** pending inserted phase 2.1 (Jellyfin transcode
retention), on operator instruction.

Prior activity: 2026-09-01 — quick task 260901-u96: read-write NFS export on atlantis for Home
Assistant backups. **Correction worth carrying into any future export work:** `nfs-music-export.tf`'s
"`ro` is forced, not a preference" is a property of the *TrueNAS-era datasets*, not of `tank`.
`tank` is `acltype=posix` (local); `tank/media/*`, `tank/downloads` and `tank/timemachine` each set
`acltype=nfsv4` locally. A new child of `tank` therefore has enforceable mode bits and `chmod`
works on it — which is the only reason a writable export is defensible. Do not generalise that `rw`
back onto anything under `/mnt/tank/media`.
Phase 1 complete: SAFE-01…05, WRIT-01…04, QUAL-01
Phase 2 complete: CONS-01, CONS-02, CONS-03

Progress: [██░░░░░░░░] 22%  *(MILESTONE progress: **2 of 9 phases** complete. All 19 plans written so far are executed 19/19 — but phases 3-9 are not planned yet, so plan-count is not milestone progress. ⚠ `gsd-sdk query state.update-progress` recomputed this as **51%** on 2026-09-02 by counting SUMMARY files against a 39-plan denominator that only covers planned phases; that figure is WRONG and was reverted. Do not let the SDK rewrite this line — phase 02.1 is an INSERTION and is not one of the 9 milestone phases.)*

Plans 02-01 through 02-09 are executed. **CONS-01, CONS-02 and CONS-03 are all complete.**

**What the operator observed, from the consumer side — two of these are independent confirmations
of things this phase proved by other means:**

- MA's browse root lists **exactly 13 artist folders**, every one a single named artist. Confirms
  **D-08** (no Various Artists compilation in this library) from the consumer side, and matches
  `sensor.music_library_nfs_mount` = 13 exactly.

- `Chris Norman / Lifelines (2026)`: 15 tracks, every row `Chris Norman • Lifelines • 2026`.
  Criterion 3 confirmed **by eye**, at track level.

- **No `Various Artists` entry anywhere; no stray singles.** The `folder_name` fallback never
  misfired on real library content.

- **`Mastermix Essential Hits - Pop 4 - 2005-2009` is ABSENT — the correct result.** It was served
  through the temporary export, torn down in 02-07. Its absence is **D-46's teardown confirmed from
  the consumer side, after the fact**.

- The `Def Leppard` **folder** is visible and that is expected — the known empty-album-artist defect
  is at album/track level *inside* it and remains deliberately unrepaired under D-05. **Do not read
  the folder's presence as the defect being resolved.**

**⚠ THE APPROVAL COVERS CRITERION 3 ONLY.** It does not close D-54b's boot blindness or the
never-delivered mount-failure notification. Both stay open — see Blockers/Concerns.

**⚠ NOTHING IS PUSHED.** The operator's 02-08 approval covered `aa2b502..90cdddc`. The tree is
**5 ahead of `origin/main`**: `a4174e6` + `6ff2332` (02-08) and `9f915a9` + `e37039b` + the 02-09
close. `/mnt/fast/stacks` on LXC 100 is therefore still at `90cdddc` and does not carry the folded-in
`quick-health-check.sh` — which does not matter, because that script runs from the workstation.

**THE FIVE CRITERIA — every one PROVEN, evidence and producing plan in `02-09-SUMMARY.md`:**
1a-1e export/re-apply/host/NUC/NFSv4.2 (02-03 + 02-05) · 2 by Stage **4b** not 4a, at the **export**
layer (02-05) · 3 exact on album name AND album artist, provider-attributed, in one 177 s sync
(02-07) · 4 by **both** 4a and 4b, a green 4a alone explicitly insufficient (02-08) · 5 this plan.

**⚠ WHAT IS NOT PROVEN, carried deliberately:** the mount-failure **notification** has never been
delivered against a genuinely bad mount (trigger path and action gate are proven by firing; delivery
is proven only as "service registered + templates render"); the literal `"0"` in that automation's
`to:` list has not fired in isolation; and **D-54b is blind at boot and NOT fixed** (see Blockers).

**CONS-03 IS COMPLETE (02-08) — the NUC was rebooted twice and both criteria are met.**

**Criterion 4a (positive):** boot_id `b86dada0…`→`3a7906c0…`, **zero manual intervention**, mount
`active`/`read_only`, sensor 13, 70 albums provider-filtered, both proof albums EXACT, audit exit 0,
M4a re-synced unprompted at 12:43:25Z. Recorded as **necessary but not sufficient** — atlantis was
healthy, so the race was never exercised.

**Criterion 4b (negative control) FIRED.** `nfs-server` stopped, NUC rebooted
(`3a7906c0…`→`a2869d72…`). Supervisor's `mounting read-only fallback` logged; `/media/music` empty
and `dr--r--r--`; MA logged `Aborting sync … scan found no files but 1244 were previously indexed`.
**The deletion guard held: 70 albums before, 70 during, 70 after. MA went stale, not empty.**

**UNATTENDED RECOVERY SETTLED: 432 s (7 m 12 s)** from `nfs-server` returning to `state: active`,
NUC untouched throughout — no `ha mounts reload`, no add-on restart, no manual mount. The measured
interval is **~7 min, not the ~900 s the research assumed**. M4b then fired on its own at
13:12:06Z and re-synced MA.

**⚠ M1 IS PROVEN (02-08), superseding 02-03 and 02-05 — do NOT re-open it.** A discriminating
client-mount pair from the NUC, same command minutes apart: dataset **mounted** → exit 0 / 14
entries; dataset **unmounted** → exit 255 / `No such file or directory` / 0 entries. The `mountpoint`
export option genuinely makes `rpc.mountd` refuse. **The earlier readings were an instrument error,
not a defect** — `exportfs -v` keeps printing the line while the dataset is unmounted, so the export
*table* is non-discriminating while the *served mount* is refused. 02-03's `threat_flag:
control-not-enforced` on `infra/nfs-music-export.tf` is **retired** and the measurement is recorded
in the file itself (`a4174e6`). M2 (`After=zfs-mount.service`) remains the boot-race guard; M1 is a
proven second layer beneath it.

**⚠ THE CONTROL FOUND A REAL ALERTING DEFECT, NOW FIXED.** D-54a's `numeric_state below: 1` trigger
was **structurally unable to fire** on a boot into a failed mount: HA arms a numeric_state trigger
only on a non-matching change, and after such a boot the sensor's first value is already `0` — there
is nothing to cross. Confirmed by contrast: M4b's `numeric_state above: 0` is a genuine crossing and
did fire. **And the obvious fix — a `state: to: "0"` trigger — would have missed it too:** the
sensor lands on its boot value 6–15 s *before* the automation attaches, and an unchanged poll fires
no event. The load-bearing fix is a `homeassistant` `event: start` trigger, which fires **at attach
time** and therefore cannot be outrun. Both new trigger paths have now fired and are
trace-confirmed; the original numeric trigger was kept, not swapped.

**D-54b is diagnosed and left OPEN, deliberately.** Its trigger config is correct (proven with a
synthetic event: fired in 542 ms). It is blind at boot because `hassio` mirrors Supervisor's issues
into HA's repairs registry ~17 s *before* the `automation` domain sets up — an ordering, not a race,
identical across four observed HA starts. Fixing it would duplicate D-54a for the only issue type in
scope and would page for pre-existing unrelated issues.

**The mount is LIVE and proven** (02-05). Route A won on measurement: a HAOS Supervisor NFS mount
named `music`, `state: active`, `read_only: true`, `user_path: /media/music`, fstype `nfs4` at
`vers=4.2` — and `/media/music` is readable **inside the running Music Assistant container**,
propagated `rslave` into a container that started two days before the mount existed. Music
Assistant's own documentation says that is impossible; it means *local bind* mounts.
**CONS-01 is COMPLETE** and **criterion 2 is proven at the export layer**: a hand-rolled
`mount -o rw` succeeded and every write was still refused `EROFS`, on NFSv3 *and* NFSv4.2.

**CONS-02 is COMPLETE (02-06). The provider exists and is pinned:**

```
instance_id                  filesystem_local--XJaJWNUS      <-- pinned in check-music-consumers.sh
domain                       filesystem_local   (Route A)
path                         /media/music       <-- NOT readable via the API; see below
content_type                 music              (read_only after setup — D-28)
missing_album_artist_action  folder_name        (default is various_artists — D-01, PERMANENT per D-02)
enabled / status / error     true / loaded / null
```

Created **entirely headlessly** (D-31): `config/providers/setup` → `config/flows/submit` →
`config/providers/save`. The GUI was never opened. `providers/manifests` is the command that lists
addable domains — `providers/available` does not exist.

**⚠ MA 2.11 does NOT expose the provider's `path`.** `config/providers/get` omits it entirely and
`config/providers/get_value {"key":"path"}` returns `Internal server error`. The path is proven
**functionally** via `music/browse "filesystem_local--XJaJWNUS://"`, which lists the 13 exported
artist directories. `02-06-SUMMARY.md` is the **only** record that the value is `/media/music`; a
rebuild must re-run the setup flow with it set explicitly, because the form's default is `/media`.

**MA's `check_write_access()` created nothing** across provider load, reload and a full initial
sync of 2,674 entries — T-02-19 closed on the real code path, not a synthetic probe.

**CRITERION 3 IS PROVEN and CONS-02 is COMPLETE (02-07)** — CONS-03 was correctly *not* ticked there,
and was closed by 02-08's reboots. All three proof albums
exact-matched on album name **and** `artists[0].name`, provider-attributed, inside one deliberately
triggered `music/sync` — **177 s**, not the 12-hour default, which stays untouched per D-38.
`check-music-consumers.sh` exits **0** in steady state. Provider-filtered album count went 20 → 70.

**⚠ THE BIGGEST FINDING IN THE PHASE: `missing_album_artist_action: folder_name` is CONDITIONAL.**
It fires only when a file's `album` **TAG** agrees with its album **FOLDER** name. When it does not,
MA silently falls back to `Various Artists` — while `config/providers/get` still reads back
`folder_name`. Isolated with a 4-cell variant matrix; the track artist tag is irrelevant (a decoy
artist still produced the folder name). **A configured setting is not a firing setting**, and album
identity is `albumartist + os.sep + album`, so a wrong album artist is durable. Phase 7 must treat
album-tag/album-folder agreement as a precondition it *checks*, not one it assumes.

It does fire, at scale: **183 times** across the real library in that one sync (Def Leppard 57,
Taylor Swift 36, Ed Sheeran 28, Katy Perry 27, Hawthorne Heights 17, Sabrina Carpenter 16).

**⚠ A live library defect, recorded and NOT repaired:** `Def Leppard/Def Leppard (2015)/` derives an
**empty** album artist (the album folder name equals the artist folder name) and hard-errors
`CD 01-06 … Sea of Love.flac`. D-05 forbids tag repair and the export is `ro`, so no remedy was
available or attempted. `zpool status -v tank` is clean — this is not scrub damage. Phase 7 inherits it.

**Both temporary artefacts are provably gone**, asserted on both sides (D-46), and those four
assertions are D-45's rollback test — **now executed once against real state**, so 02-09 documents a
tested procedure. `exportfs -v` shows one `/mnt/tank` line, byte-identical to 02-03's; the second
provider is absent; its `library_items` is `[]`; `terraform plan -detailed-exitcode` is 0. The
scratch dataset was destroyed too (Terraform recreates it on the next enable).

**RESOLVED — the `scp` workaround is RETIRED.** The 41 local commits were pushed to `origin/main`
with explicit operator approval (`aa2b502..90cdddc`, clean `git pull --rebase`, no conflicts), and
`git pull --ff-only` in `/mnt/fast/stacks` on LXC 100 now lands
`scripts/check-music-consumers.sh` — verified 2026-09-01, script present at HEAD `90cdddc` and run
from there for both of 02-08's audit gates. **02-09's fold-in into `quick-health-check.sh` therefore
has a real pull path**, which closes the blocker 02-05, 02-07 and 02-08's first half all flagged.

Before any Terraform work, read the CORRECTION entries under Blockers/Concerns — a bare
`terraform apply` was measured to be one command away from destroying LXC 100, and port 111 was
already open so only 2049 is this phase's delta.

## Performance Metrics

**Velocity:**

- Total plans completed: 18
- Average duration: ~42m (excluding 01-06's 374-minute observation window)
- Total execution time: ~375m of work

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 9 | ~375m | ~42m |
| 02 | 9 | - | - |

**Per Plan:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| 01-01 | 20m | 3 tasks | 1 file |
| 01-02 | 25m | 3 tasks | 1 file |
| 01-03 | 45m | 3 tasks | 2 files |

**Recent Trend:**

- Last 5 plans: 01-01 (20m), 01-02 (25m), 01-03 (45m)
- Trend: rising — 01-03 carried a 9,736-file measurement run, not just script authoring

*Updated after each plan completion*
| Phase 01 P04 | 55m | 2 tasks | 1 files |
| Phase 01 P05 | 35 minutes | 3 tasks | 10 files |
| Phase 01 P06 | 65m + 374m watch | 3 tasks | 3 files |
| Phase 01 P07 | ~40 minutes | 2 tasks | 3 files |
| Phase 01 P08 | ~35 minutes | 3 tasks | 2 files |
| Phase 01 P09 | ~55 minutes | 4 tasks | 5 files |
| Phase 02 P02 | 28min | 3 tasks | 3 files |
| Phase 02 P01 | 75m | 4 tasks | 3 files |
| Phase 02 P03 | 25min | 3 tasks | 2 files |
| Phase 02 P04 | 78min | 3 tasks | 1 files |
| Phase 02 P05 | 13min | 3 tasks | 1 files |
| Phase 02 P06 | 6min | 2 tasks | 1 files |
| Phase 02 P07 | 27min | 3 tasks | 2 files |
| Phase 02 P08 | 195m | 3 tasks | 3 files |
| Phase 02 P09 | 50 min | 3 tasks | 5 files |
| Phase 02.1 P01 | 12 minutes | 3 tasks | 3 files |
| Phase 02.1 P02 | ~29 minutes (two agents) | 2 tasks | 3 files |
| Phase 02.1 P03 | ~13 minutes (continuation agent) | 2 tasks | 5 files |
| Phase 02.1 P04 | 36 minutes | 3 tasks | 3 files |
| Phase 02.1 P05 | ~25 minutes | 2 tasks | 6 files |

## Accumulated Context

### Roadmap Evolution

- Phase 02.1 inserted after Phase 2: Jellyfin transcode retention — relocate the anonymous transcode volume off / and set a retention policy (URGENT)

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [02.1-05]: **VALIDATION row 15's key-set equality was CORRECTED, not waived.** It names
  `ThrottleDelaySeconds` as a changed key, but that value was already `180`, so setting it to `180`
  changed nothing and the equality was unsatisfiable as written — the plan's own prose, the research
  and `jellyfin.yaml` all say `180 -> 180 UNCHANGED`. It conflates "keys SET in the POST body" with
  "keys whose VALUE CHANGED". Replaced with the **subset** direction (`changed − intended == []`,
  which *is* the full-object-replace hazard) **plus** the value assertion — together strictly
  stronger, because a key-set comparison is silent on values and would pass a key changed to the
  *wrong* value. **The row still needs fixing in VALIDATION.md before 02.1-10.**

- [02.1-05]: a stopped **guard container** held the anonymous volume through the recreate, because
  whether compose v5 passes `RemoveVolumes` on `--force-recreate` is undocumented and is not a
  question worth answering by losing the rollback. The answer, for the record: **it does not.** The
  guard was created from the already-resident image (no pull) and removed immediately after, without
  `-v`.

- [02.1-05]: **TRAN-01 marked COMPLETE**, as 02.1-04 said it should be — the declaration and the
  writes finally agree. **TRAN-02, TRAN-03 and TRAN-04 stay Pending despite this plan's frontmatter
  claiming them**: TRAN-02 needs the volume *gone* (02.1-06), and TRAN-03/TRAN-04 need the bounds
  proven **firing** from Jellyfin's own logs rather than read back from the API (02.1-08) — which is
  exactly what this plan did. CONS-04's rule; Phase 2 paid to learn it.

- [02.1-05]: the pre-cutover reconciliation copied 10 live-cache files **deterministically** rather
  than letting row 6's tolerance absorb them, so the 99% floor stays a guard against *collapse*
  rather than a way of tolerating a stale copy. `rsync` is still absent and still deliberately not
  installed; the documented `cp` equivalence was used with per-file exit status.

- [02.1-04]: `transcodes/` (12.55 GiB, 1,324 files) was EXCLUDED from the cache copy — it is
  shadowed by the nested `/cache/transcodes` bind, it is deleted wholesale in 02.1-06, and copying
  it would breach the plan's own headroom precondition. The 391 MiB actually copied is the "392 MiB"
  every plan in this phase reasons about.

- [02.1-04]: the plan's literal headroom precondition (`floor + 2x source`) was REPLACED, not
  waived. Its `2x` term assumes a same-filesystem transient double; `stat -c %d` measures source on
  dev 64519 (ext4, `/`) and destination on dev 63 (zfs), so `/` consumption is zero. Measured
  outcome: `/` went UP 14.0 MiB across the copy.

- [02.1-04]: `rsync` is NOT INSTALLED on LXC 100 and was deliberately not installed — a package
  install to copy 391 MiB that `cp` copies correctly adds supply-chain surface for no gain. The
  documented equivalence `cp -r -d --preserve=timestamps` == `rsync -rlt --no-p --no-o --no-g` was
  used, with per-file exit status branched on rather than a printed summary.

- [02.1-04]: assumption **A5 CONFIRMED** — `fast/appdata/media` is `acltype=nfsv4` with
  `aclmode=passthrough` (not `restricted`), and `cp --preserve=all` succeeds there preserving mode
  and ownership. The `tank` EPERM failure mode does not apply to this dataset.

- [Roadmap]: Harness before spike — every harness item is tagger-independent and several protect
  assets that cannot be recreated.

- [Roadmap]: Phase 2 (NFS/MA) runs in parallel from the start and must complete before Phase 7 —
  Music Assistant never purges stale entries, so it is proven before content flows, not after.

- [Roadmap]: Phase 4 (retirement) is independently shippable — a fourth stall must still leave the
  estate with one tagger, one database, no idle container holding a rw mount.

- [Revision 2026-08-17]: **The library is not empty, so "it imported" is not the bar — "it did not
  get worse" is.** QUAL-01 puts a re-runnable before-state tag snapshot in Phase 1, before anything
  is staged; QUAL-02 gates the pilot on a field-level before/after diff with no net metadata loss.
  A file can pass CONS-04 in full while having lost fields it arrived with.

- [01-09 / Phase 1 closure]: **Library ownership is `568:568`; modes stay `0777`.** `568` is `apps`
  (four independent repo references, 76% of 535,298 media entries); the gid it replaced, **545, is
  an orphan** — `getent group 545` returns nothing on atlantis. The `0755`/`0644` target is recorded
  but **not achieved**: `chmod` fails `EPERM` on `tank` even as real root. Phase 2's export must be
  read-only as a result.

- [01-09 / Phase 1 closure]: **Jellyfin's Music metadata freeze is permanent, and Jellyfin stays the
  documented sole `rw` holder rather than going `:ro`** — consumer-class, frozen at the application
  layer, counted in its own audit class. Measured limit: `SaveLocalMetadata: false` does not stop an
  explicit `FullRefresh`.

- [02-09 / Phase 2 closure]: **Route A wins — Music Assistant reads the library through an HA
  Supervisor NFS network-storage mount, not through MA's own remote-share provider.** The losing
  route's failure symptom, recorded so it is not revisited: **Route B exposes no client-side `ro`
  option at all** (MA hardcodes its NFS option list), so it would have discarded a layer of defence
  in depth. MA's own documentation is **empirically disproven** on the sentence that created the open
  question — `docker exec … ls /media/music` inside the running add-on returns the 13 artist
  directories. PROJECT.md's prior "OPEN QUESTION" passage is **rewritten**, not supplemented.

- [02-09 / Phase 2 closure]: **`missing_album_artist_action: folder_name` is permanent — and it is
  CONDITIONAL.** It fires only when a file's `album` **tag** agrees with its album **folder** name;
  on a mismatch MA silently yields `Various Artists` while `config/providers/get` still reads back
  `folder_name`. **Reading the setting back is not proof it applies, and the API cannot tell you it
  did not fire.** Phase 7 must check the precondition, not assume it.

- [02-09 / Phase 2 closure]: **The export's `mountpoint` option stays, and is PROVEN** by
  control-probe-control (mounted → exit 0/14 entries; unmounted → exit 255/ENOENT/0; remounted →
  exit 0/14). It is in **neither** of CLAUDE.md's original candidate option sets. `ro` is **forced**,
  not chosen: the tree is `0777` and ZFS NFSv4 ACLs are not exported by knfsd, so mode bits are the
  only lever a client sees.

- [02-09 / Phase 2 closure]: **`sec=sys` on a trusted LAN is an accepted residual risk, recorded as a
  CHOICE.** Anything that can present as `172.16.1.31` can read the library. `xprtsec=` (RFC 9289,
  needs `tlshd` both ends) and `sec=krb5` (needs a KDC, unproven on HAOS) were both considered and
  rejected. The tailnet address is deliberately absent from the export line.

- [02-09 / Phase 2 closure]: **Standing coverage beats a one-off proof.**
  `scripts/check-music-consumers.sh` is folded into `scripts/quick-health-check.sh`, the path already
  in use. With the MA add-on on `auto_update` against a BETA (`2.11.0b0`), this is the only detector
  of an MA release changing provider behaviour under the pipeline.

- [01-09 / Phase 1 closure]: **`quick-health-check.sh` can now exit non-zero**, and the freeze
  harness runs on it. The library **mode** assertion was scoped to a report inside
  `check-music-freeze.sh` — a permanently-red check trains the reader to ignore it, which is the
  failure the fold-in exists to prevent. Ownership stays a hard assertion.

- [01-09 / Phase 1 closure]: **`/mnt/tank/media/TV` — 114,218 entries on orphan gid 545 — is
  recorded, not actioned.** No requirement covers it, and scope growth followed by abandonment is
  this project's documented failure mode. Working method recorded in `beets.md` (run `chown` from
  the Proxmox host, never LXC 100).

- [01-09 / Phase 1 closure]: **Six times this phase a check reported a pass it had not earned**, all
  from the same root: partial data stated as settled. The rule now written into `beets.md` — verify
  with a second independent instrument before writing it down.

- [Revision 2026-08-17]: **Ergonomics is a scored axis in the Phase 3 spike, not a footnote**
  (TAGR-06). Two separate questions: which engine (beets vs wrtag) and how the human meets it (raw
  CLI vs a reviewable queue). beets-flask is evaluated by name on the second. The operator's
  first-hand experience is that beets has been painful to get working, and a painful tool is the
  documented cause of all three prior abandonments — so the second axis may decide whether this
  finishes more than the first does.

- [Revision 2026-08-17]: **The pilot must meet the hard shapes** (QUAL-03) — at least one
  various-artist compilation and one multi-disc release, both historically painful here. Twelve
  clean single-artist albums would prove a flow that has never faced the real case, and would leave
  CONF-03 / CONF-05 asserted rather than exercised.

- [Revision 2026-08-17]: **Undo is a pilot gate** (QUAL-04), not a nice-to-have. At Phase 9 scale,
  "I cannot cleanly back this out" is indistinguishable from abandonment.

- [Revision 2026-08-17]: Replacing Lidarr is wanted and recorded as LIDR-01 in v2, deliberately not
  in this milestone. WRIT-03 already stops it writing to the library, which removes the harm; the
  rest is a separate project with its own migration.

- [01-01]: zfs is not resolvable inside LXC 100 (unprivileged); harness zfs queries are delegated over ssh to the Proxmox host 172.16.1.158
- [01-01]: audit scripts exit 1 on any failed assertion, exit 0 only in --baseline mode; the estate had no such convention and its silence hid a six-week outage
- [01-01]: WRIT-04 is ~2x its assumed size — 2,543 of 2,673 library entries have the wrong owner and every file and directory is mode 0777, so D-13's chmod pass touches 100% of the tree
- [Phase ?]: [01-03]: audio_md5 (ffmpeg -map 0:a -c copy -f md5) is the QUAL-01/QUAL-02 join key; proven by a flat 2CD set where all 21 track numbers collide and neither path nor filename disambiguates the disc
- [Phase ?]: [01-03]: D-02 scope is 9,736 audio files and 170.12 GiB, not 9,764 and ~140 GB; plan 01-04 projects to ~36 min, CPU-bound on md5 hashing and single-threaded, so it can run attended
- [Phase ?]: [01-03]: the unsorted and dj-mixes copies of Now! 120 are the SAME rip - 20/20 audio_md5 shared, 0 unique to either side; first hard DUPE-01 measurement, covering 1 of the 85 shared folder names
- [Phase ?]: [01-02]: fence copies made with sqlite3 .backup are verified with PRAGMA integrity_check, not sha256 equality — the plan mandated both and they are mutually unsatisfiable; cover scans still held to strict sha256
- [Phase ?]: [01-02]: the Mac Mini's non-interactive ssh PATH lacks head/basename/sqlite3 — verification over ssh must use absolute tool paths and keep stderr, or it fails closed and reports false corruption (cost two false 'all 15 databases bad' results)
- [Phase ?]: [01-02]: '794 dj-mixes files' is wrong — there are 764 audio files; the 794 figure was 764 audio + 30 jpg and missed the 24 BMP cover scans entirely
- [Phase ?]: 01-05: Photos gets no mount in any narrowed container — only Jellyfin retains it via its D-21 carve-out; containers able to reach it went 8 -> 1
- [Phase ?]: 01-05: wrtag frozen via 'compose --profile manual down'; a plain 'compose up -d' on the music stack now returns 'no service selected' — the gate is proven, not asserted
- [Phase ?]: 01-05: lidarr deliberately untouched (01-06 owns WRIT-03), so it is the single remaining rw holder in BOTH audit classes — expected, not a regression
- 01-06: WRIT-03 met — lidarr root folder off the library, renameTracks off, all metadata consumers off (already were), media mount :ro proven by an in-container write attempt; tagger-class rw holders on the library is now 0
- 01-06: deleting an *arr root folder does NOT repoint its artists — all 22 lidarr artists keep absolute /media/Music paths, so D-25's :ro mount is the load-bearing control, not D-23's root-folder move
- 01-06: SaveLyricsWithMedia is a THIRD Jellyfin write switch that SaveLocalMetadata does not gate; it wrote 944 of the 1,123 baseline sidecars. Any "is Jellyfin frozen?" check that reads only SaveLocalMetadata gives a false pass
- 01-06: lidarr had a DELETE path into the library (mediamanagement.deleteEmptyFolders: true) that WRIT-03 and D-24 do not count as a write path; now false
- 01-06: the SAFE-05 sidecar set is widened to .nfo/.jpg/.lrc/.png/.txt — 1,341 files, 19.4% more than D-18's 1,123; the narrow subtotal is still printed for comparability with the 01-01 baseline
- 01-06: **the SAFE-05 test as the roadmap words it is a path-set diff, and a path-set diff is structurally blind to the most likely form of Jellyfin pollution.** Measured: it returned 0 added / 0 removed while Jellyfin rewrote 83 of the library's 91 .nfo in place, 66 with genuinely changed content. Widening the extension set does NOT fix this — the comparison had to change. The watch now checks sha256 content, a whole-library size/mtime manifest, and a ZFS snapshot cross-check
- 01-06: **SaveLocalMetadata=false does NOT stop an explicit Jellyfin FullRefresh writing .nfo.** It gates the automatic scan-time save path only. The first .nfo was rewritten 1 second after the refresh POST, with the setting already false and read back from the API. SAFE-05 is true for "Jellyfin writes nothing unprompted" and FALSE for "Jellyfin cannot write" — a UI "Refresh metadata" click still writes. The only structural control would be an :ro mount, which D-21 deliberately rejected
- 01-06: the @pre-project ZFS snapshot was used in anger and works — SAFE-02 proven, not asserted. `snapdir=hidden`, so `/mnt/tank/media/Music/.zfs/snapshot/pre-project` must be typed; it will not list
- [Phase ?]: There are five beets configs in the estate, not three — beets' scrub/lastgenre/embedart/fetchart auto keys all DEFAULT to on, so an absent key was an armed key
- [Phase ?]: appdata/arrs/beets/config/config.yaml is a docker-compose file saved into BEETSDIR — beets ran on pure defaults and imported 47 tracks into /config/Music/__/
- [Phase ?]: find -xdev is unsafe for estate sweeps: /mnt/fast/appdata/* are separate ZFS datasets, so a sweep from /mnt/fast silently skips appdata and exits 0
- [Phase ?]: 01-08: the WRIT-04 chown must run on the Proxmox host - LXC 100 is unprivileged and physically cannot chown the library's unmapped uids/gids (EPERM, a different mechanism from aclmode=restricted with the same errno)
- [Phase ?]: 01-08: the 01-01 ownership census recorded the CONTAINER's view, not the disk - six on-disk owners collapse to five, and its writer attributions are wrong
- [Phase ?]: 01-08: D-11's 568:568 confirmed on evidence - Music was the only media subtree on gid 545 while Movies was already 568:568, so beets.md's 568:545 describes drift and D-14 stands
- [Phase ?]: 01-08: mode pass skipped with a printed explanation rather than run or swallowed; no zfs set of any property was executed
- [Phase ?]: 01-08 CORRECTION: gid 545 is NOT Music-specific - TV carries 114,218 entries on the same orphan gid (48x Music). The estate is split: Music+TV on 545, Photos+Movies+Books on 568. D-11's 568:568 still stands, but because 545 is an orphan gid (no group entry, unmapped in the LXC idmap) and 568 is the documented convention - not because Music was uniquely wrong
- [Phase ?]: 01-08: uid 3000 owns 197,776 of tank/downloads' 209,039 entries (94.6%) - the download client's identity, and the same uid as the library's .DS_Store; resolve before Phase 5 stages _inbox there
- [Phase ?]: 02-02: NFS music export defined in Terraform (infra/nfs-music-export.tf) - ro,all_squash,anonuid/anongid interpolated from var.apps_uid/gid, mountpoint, no_subtree_check, sec=sys, to 172.16.1.31 only; fsid=, crossmnt and no_root_squash absent with recorded reasons
- [Phase ?]: 02-02: xprtsec= (RFC 9289) and sec=krb5 considered and rejected in the file header; sec=sys on a trusted LAN recorded as an accepted residual risk
- [Phase ?]: 02-02: temporary control export is count-gated on music_temp_export_enabled (default false) - teardown is a terraform apply, not a memory
- [Phase ?]: 02-03: NFS export APPLIED and live — ro,all_squash,anonuid=568,anongid=568,mountpoint to 172.16.1.31 only; re-apply exit 0; served from atlantis, LXC 100 proven unable (unprivileged)
- [Phase ?]: 02-03: M1 (mountpoint export option) is NOT enforced at exportfs time on nfs-utils 1:2.8.3-1 — exportfs -au + -a silently re-creates the line while the dataset is unmounted. Configured-but-UNPROVEN; M2 (After=zfs-mount.service) is the proven guard; 02-05 must settle it client-side
- [Phase ?]: 02-03: CONS-01 deliberately NOT ticked — criterion 1 parts 1d/1e need a client and belong to 02-05; traceability row records the interim state
- [Phase 2]: 02-04: MA 2.11 has no API-token UI — check-music-consumers.sh logs in per run rather than caching the 90-day JWT, so the credential cannot expire silently inside an unattended check (D-39 intent, not its literal 365-day wording)
- [Phase 2]: 02-04: music/albums/count has NO provider parameter (returned 87 with and without one) — mount liveness uses provider-filtered music/albums/library_items instead; count would report green off Spotify's catalogue with the NFS mount absent
- [Phase 2]: 02-04: D-08 fired — the library has no Various Artists compilation (all 13 folders are single named artists), so the VA shape is substituted by VA-Mastermix.Essential.Hits.Pop.4 from the backlog, staged by 02-07 under the temporary export
- [Phase 2]: 02-05: ROUTE A WINS on measurement — /media/music is readable INSIDE the running Music Assistant container (rslave, master:1105, container up 2 days before the mount existed). MA's own docs say this is impossible; they mean local bind mounts. Route B's failure symptom: it exposes no client-side ro option at all
- [Phase 2]: 02-05: CRITERION 2 PROVEN AT THE EXPORT LAYER — a hand-rolled mount -o rw succeeded and every write was still refused EROFS. Re-run over NFSv4.2 because the plain mount -o rw negotiated vers=3, which is NOT the version MA reads through. Read-only holds on both
- [Phase 2]: 02-05: CONS-01 is COMPLETE — 1d proven by nc 2049 exit 0 plus a successful mount (showmount is absent on the NUC), 1e by /proc/self/mountinfo fstype nfs4 vers=4.2 (findmnt is absent too)
- [Phase 2]: 02-05: ssh -n EATS A HEREDOC — -n points stdin at /dev/null so 'ssh -n host bash -s <<EOF' discards the whole script and exits 0. Use -n for inline 'ssh host cmd' ONLY; never when feeding a script over stdin
- [Phase 2]: 02-05: the NFSv4 pseudo-root entries in /proc/fs/nfsd/exports carry no_root_squash (/, /mnt, /mnt/tank, /mnt/tank/media — all v4root and ro). Not a T-02-06 regression, but a grep of that table returns 4. Assert on exportfs -v, which check-music-consumers.sh already does
- [Phase 2]: 02-06: missing_album_artist_action=folder_name on the MA filesystem_local provider is PERMANENT (D-02), not a pilot setting
- [Phase 2]: 02-06: the MA provider was created entirely HEADLESSLY via config/providers/setup + config/flows/submit + config/providers/save (D-31); the GUI was never opened
- [Phase 2]: 02-06: MA 2.11 does NOT expose the filesystem provider's path via config/providers/get; /media/music is proven functionally via music/browse and recorded only in 02-06-SUMMARY.md
- [Phase 2]: 02-07: CRITERION 3 PROVEN — three albums exact-matched on album name AND artists[0].name, provider-attributed, in 177s via a deliberate music/sync rather than the 12-hour default (D-38 untouched)
- [Phase 2]: 02-07: missing_album_artist_action=folder_name is CONDITIONAL — it fires ONLY when the album TAG matches the album FOLDER name; otherwise MA silently uses Various Artists while config/providers/get still reads back folder_name. Isolated with a 4-cell variant matrix; the track artist tag is irrelevant
- [Phase 2]: 02-07: Def Leppard/Def Leppard (2015)/ derives an EMPTY album artist and hard-errors one file, because the album folder name equals the artist folder name. Recorded NOT repaired — D-05 forbids tag repair and the export is ro
- [Phase 2]: 02-07: a null_resource destroy removes NOTHING from the host — music_temp_export_enabled=false was not a teardown until 02-07 added an always-present reconciler resource. A destroy-time provisioner cannot be used: terraform validate refuses it, and the workaround puts the Proxmox root password in plaintext state and in every plan diff
- [Phase 2]: 02-07: MA 2.11's search arg on music/albums/library_items is NOT a substring match — searching an album's OWN EXACT NAME returned [] while a one-word prefix returned it. Filter on provider only and do the exact match locally, or the gate reports a false FAILURE
- [Phase 2]: 02-07: config/providers/remove is a COMPLETE purge of everything exclusive to that instance (84->79 albums, exactly -5; 55 tracks, 47 artists), no orphans — and it drops every favourite and play count attached to them
- [Phase 2]: 02-08: CONS-03 COMPLETE — criterion 4a passed (boot_id changed, zero manual intervention, 70 albums, both proof albums EXACT) and criterion 4b FIRED (Supervisor read-only fallback, MA 'Aborting sync … 1244 previously indexed', 70 albums preserved through the degraded window — stale not empty)
- [Phase 2]: 02-08: unattended recovery of a failed HAOS media mount is REAL and takes 432 s (7 m 12 s) on this estate at this version, not the ~900 s the research assumed — NUC untouched throughout, and M4b re-synced MA on its own at 13:12:06Z
- [Phase 2]: 02-08: M1 IS PROVEN, superseding 02-03 and 02-05 — the mountpoint export option DOES make rpc.mountd refuse a fresh client mount when the dataset is unmounted (exit 0/14 entries mounted vs exit 255/ENOENT/0 unmounted). The earlier 'unproven' readings were an INSTRUMENT ERROR: exportfs -v keeps printing the line, so the export table is non-discriminating while the served mount is refused
- [Phase 2]: 02-08: 'mount | grep emergency/music' can NEVER match on this Supervisor version — it makes the media directory read-only IN PLACE (dr--r--r--, 0 entries) rather than bind-mounting /mnt/data/supervisor/emergency/music. The working proof line is /media/music empty and dr--r--r--
- [Phase 2]: 02-08: an HA numeric_state trigger fires on a CROSSING and is armed only by a non-matching change, so it is structurally unable to fire on a boot into an already-failed state — and a state 'to:' trigger misses it too, because the sensor lands on its boot value 6-15 s BEFORE the automation attaches. Only a 'homeassistant event: start' trigger, which fires at attach time, can catch a fault that predates the automation
- [Phase 2]: 02-08: put the debounce in the ACTION (delay + re-read) rather than 'for:' on the trigger — 'for:' leaves no trace that the trigger ever armed, which is exactly how D-54a's defect stayed hidden for a plan and a half
- [Phase 2]: 02-08: D-54b's repairs-issue trigger is correct (synthetic event fired it in 542 ms) but is blind at boot by ORDERING not race — hassio mirrors Supervisor issues into HA's repairs registry ~17 s before the automation domain sets up, identically across four observed HA starts. Left open deliberately
- [Phase 2]: 02-08: the default 'ha supervisor logs' window does not reach back to boot — a default-depth grep for 'read-only fallback' returns nothing and is indistinguishable from 'it did not happen'. Use -n 2000 or deeper
- [Phase 2]: 02-08: the HAOS SSH add-on is NOT privilege-limited — sudo is NOPASSWD:ALL, CapBnd carries CAP_SYS_ADMIN and Protection mode is already off. The 02-05/02-08 probes failed for want of 'sudo', not for want of privilege
- [Phase ?]: 02.1-01: TRAN-01..09 are a PHASE INSERTION, not a milestone scope change — the v1 denominator stays at 39 and the nine are subtotalled separately (39 + 9 = 48). Incrementing it would make every prior 'N of 39' statement incomparable with every later one, in a milestone that is already part-executed
- [Phase ?]: 02.1-01: PHASE-START READING IS NOT WHAT THE PLAN SET ASSUMED — / is at 20.18 GiB avail, only 185 MiB above the D-17 20 GiB floor, not the ~33-36 GiB the plans were written against. The transcode cache has ALREADY refilled to 12.55 GiB across 1,324 files since the container came up 2026-08-31 (~6 GiB/day). The D-32 gate passes so the phase proceeds, but at that rate / crosses the floor in ~1 day and hits zero in ~3. Any stall — especially 02.1-09's blocking human gate — spends a budget measured in hours. Verified with stat -f as a second instrument
- [Phase ?]: [02.1-02]: jq's `//` is the ALTERNATIVE operator and treats `false` as empty as well as `null` — never use it to read a boolean back. The standing check's own first --baseline printed EnableSegmentDeletion, EnableThrottling and EnableHardwareEncoding as `<absent>` when all three were genuinely `false`, including the amdgpu mitigation flag where absent and false carry OPPOSITE implications for a ~6-hour outage hazard. An <absent> baseline would also have made 02.1-07's before/after read as 'the key appeared' rather than 'the value moved'
- [Phase ?]: [02.1-02]: a green `zfs get quota` on an UNMOUNTED dataset is a false pass — the bind still works, the container still writes, and the quota does not apply, while the property still reads 53687091200. The standing check asserts `mounted` by two instruments with no shared failure mode: the ZFS property from atlantis over ssh, and a container-side `stat -c %d` device-id comparison that needs neither ssh nor zfs. Baseline confirms the split is real: mounted GREEN, quota RED
- [Phase ?]: [02.1-02]: `/` margin is 182.6 MiB, tripping 02.1-02's own ~5 GiB stop condition. The plan was finished anyway because every action in it is read-only with respect to `/`. **The operator ordering decision is OWED BEFORE 02.1-03** (the first mutation): should 02.1-09's image reap move ahead of it? D-31 put the reap last when the plan set assumed ~13 GiB. Also measured: the cache was byte-identical across two watch samples 16 min apart — it grows during playback, not on a wall clock
- [Phase 02.1]: [02.1-03]: OPERATOR RULED OPTION B on the pre-existing exit-2 Terraform drift — clear it as its own separate, mechanically-asserted no-op apply FIRST, then execute against a genuinely clean exit-0 baseline. Chosen over proceeding with a documented exception because VALIDATION row 28 is a row this phase gets verified against and only B satisfies it literally. Two applies, each from its own saved workstation-local plan file, each asserted before it ran: count=0/destroys=0/addresses=[] then count=1/destroys=0/addresses=[null_resource.jellyfin_transcode_dataset]. Neither plan file was committed
- [Phase 02.1]: [02.1-03]: ASSUMPTION A3 IS CONFIRMED, BYTE-EXACT — df -B1 --output=size /mnt/fast/transcode inside LXC 100 went 1442767175680 to 53687091200, zero delta against the target, corroborated by stat -f (51200 blocks x 1048576 bsize). ZFS derives statvfs f_blocks from referenced+available with available capped by the quota, so the standing check gains a second instrument for the bound that needs neither ssh nor zfs. It proves the quota is SET, never that it FIRES — that is 02.1-08, and row 9 stays the primary
- [Phase 02.1]: [02.1-03]: TRAN-07 COMPLETE, TRAN-03 deliberately NOT — TRAN-07's two clauses (declared in infra/ Terraform; the apply provably scoped to that one resource with zero destroys) are both discharged with committed evidence, while TRAN-03 requires the bound proven FIRING rather than set. Read back from atlantis: quota=53687091200, compression=off, sync=disabled, recordsize=1048576, atime=off, mounted=yes, and stat 2775 apps:apps — the setgid bit survived the guarded chown plus unconditional chmod

### Pending Todos

- ~~01-06 Task 3 — the SAFE-05 watch~~ **PASSED 2026-08-18T20:54:49Z**, 374 minutes elapsed. All
  four content-aware gates zero: sidecars added 0, removed 0, content-changed 0, whole-library stat
  delta 0. `zfs diff` returned exactly one line — a permission probe from the `aclmode`
  investigation whose `ctime` moved while sha256, size, mtime, owner and mode stayed identical
  across live, `@safe05-watch-t0` and `@pre-project`. Independently re-run and reproduced.

- ~~01-06 open question: restore the 66 changed `.nfo`?~~ **DECIDED: no.** They are Jellyfin's own
  current metadata rather than damage, both ZFS snapshots hold the originals indefinitely, no audio
  file was touched, and restoring would mean writing into a library this phase just finished
  sealing in order to undo a write.

- **Decision recorded: the SAFE-05 window was kept QUIET on purpose.** `RefreshLibrary` was
  deliberately not triggered. Since an explicit `FullRefresh` is now *known* to write, an "active"
  window would be provoking the failure rather than testing the claim. The quiet result proves what
  SAFE-05 can honestly support — nothing writes unprompted — and the explicit-refresh hole is
  recorded beside the pass, not behind it.

### Blockers/Concerns

- **v1 is now 39 requirements** (was 34; earlier the header wrongly said 33). Arithmetic checks
  both ways: by category SAFE 5 + WRIT 4 + CONS 4 + TAGR 6 + CONF 6 + INBX 3 + QUAL 4 + IMPT 3 +
  INGS 4 = 39; by phase 10 + 3 + 3 + 3 + 3 + 6 + 6 + 4 + 1 = 39. No requirement is unmapped and
  appears twice.

- **Ordering hazard: QUAL-01 must complete before Phase 5 stages anything.** Once content is moved
  into the inbox or imported, the before-state can no longer be recovered and Phase 7's diff has
  nothing to compare against. This is now an explicit dependency on Phase 5.

- ~~**Phase 2 route unresolved:** HAOS `/media` mount vs Music Assistant's own remote-share
  provider.~~ **RESOLVED 2026-09-01 (02-05, recorded 02-09): Route A, on measurement.** MA's own
  documentation is the side that was wrong. Route B's failure symptom is recorded in PROJECT.md so
  this is not re-litigated: it exposes no client-side `ro` option at all.

- **⚠ OPEN, carried past Phase 2: `music02_supervisor_issue_raised` (D-54b) is BLIND AT BOOT.** Its
  trigger config is correct — a synthetic event fired it in 542 ms — but `hassio` mirrors Supervisor
  issues into HA's repairs registry **13–18 s before the `automation` domain sets up**, consistently
  across four observed starts. A genuine `{action: create, domain: hassio}` event at `12:51:53.032Z`
  hit a trigger that attached at `12:52:21.951Z`. `hassio` is bootstrap-stage and `automation` is
  not, so it misses **every** time, not sometimes. **Recorded fix:** a state-based `command_line`
  sensor against `http://supervisor/resolution/info` using `$SUPERVISOR_TOKEN` at startup, instead of
  the create event. Rejected for now because it duplicates `music02_nfs_mount_failed_alert` (which
  now has its own boot trigger) for the only issue type in scope, and scoped wider it would page
  repeatedly for pre-existing issues nobody has chosen to act on. Also open: the mount-failure
  **notification** has never been delivered against a genuinely bad mount.

- **⚠ A live library defect, recorded and deliberately UNREPAIRED:**
  `/mnt/tank/media/Music/Def Leppard/Def Leppard (2015)/` derives an **empty** album artist and
  hard-errors `CD 01-06 … Sea of Love.flac`, because the album folder name equals the artist folder
  name. D-05 forbids tag repair, nobody holds `rw` on Music until Phase 6, and the export is `ro`.
  `zpool status -v tank` is clean, so it is **not** scrub damage. Handed to Phase 7.

- **Phase 3 drift risk:** the spike must carry pre-committed overturning thresholds and a
  ~20-folder normalisation pre-step, or the Discogs number is invalid and the phase becomes tool
  advocacy.

- **Abandonment is the dominant risk, 3-for-3 historically.** Leading indicator: more than ~10 days
  since the last import ran. All three prior deaths look identical at day 10. The revision attacks
  this directly on two fronts: TAGR-06 makes "will I actually still open this in week six" a
  recorded spike output, and QUAL-04 makes a clean undo something proven at pilot scale rather than
  hoped for at backlog scale.

- ~~SAFE-05 blind spot (found in the 01-01 baseline): the library holds 43 .png and 175 .txt files outside D-18's .nfo/.jpg/.lrc sidecar definition.~~ **RESOLVED 2026-08-18 by 01-06** — `check-music-freeze.sh` section 5 now inventories `.nfo/.jpg/.lrc/.png/.txt` (1,341 files) and prints the narrow D-18 subtotal (1,123) alongside it so the widening stays auditable against the 01-01 baseline. `.DS_Store` is counted separately.

- ~~**BLOCKER for 01-08**~~ **RESOLVED by scoping (`b02dfb7`): D-12 is out; 01-08 delivers the
  ownership half of WRIT-04 only, its Task 2 is a confirmation rather than a mode-change pilot, and
  `zfs set aclmode=passthrough` is explicitly rejected. The finding itself stands and still governs
  Phase 2.** — `chmod` is impossible anywhere on `tank`. `tank/media`, `tank/media/Music`
  and `tank/downloads` all carry `acltype=nfsv4` + `aclmode=restricted` + `aclinherit=passthrough`.
  Every child inherits a non-trivial NFSv4 ACL, and `restricted` makes `chmod` on a non-trivial ACL
  return `EPERM` — **as root, for every mode, including a no-op `chmod 0777` on a file already at
  0777.** Measured directly during 01-06. Consequences:

  - **D-12/D-13's mode normalisation (87 dirs → 0755, 2,586 files → 0644) cannot be done with
    `chmod`.** `chown` is unaffected and still works, which is why 01-08 keeps the ownership half.

  - It explains 01-01's "every entry is mode 0777 with no exceptions" — nothing can change them.
  - It is the same root cause as PROJECT.md's documented `rsync -a` failure
    (`mkstemp ... Operation not permitted`).

  - Phase 2 inherits it: knfsd does not export NFSv4 ACLs, so mode bits are all an NFS client sees,
    and mode bits currently cannot be set below 0777.

  - Routes considered: (a) `zfs set aclmode=passthrough|discard` on the datasets, (b) install
    `nfs4-acl-tools` (absent on LXC 100 and on the Proxmox host), or (c) accept 0777 and drop D-12.
    **(c) was chosen** — 01-06 deliberately changed nothing and escalated; the user reproduced the
    result independently and scoped D-12 out in `b02dfb7`, explicitly rejecting (a).

- 01-06: a `.DS_Store` owned `65534:65534` sits in the library root — a macOS client has write access
  over a share. It is an uncounted writer that no container mount audit and no Lidarr or Jellyfin
  setting can close, and no current requirement covers it. The harness now counts it every run.

- 01-06: the fenced `jellyfin-jellyfin.db` carries an `ApiKeys` table with 4 admin-scoped rows. It is
  mode `0600` rather than the fence's usual `0644`. If `library-db/` is copied off-box again under
  D-07, those credentials travel with it.

- ~~01-02 task 3 blocked at checkpoint: off-box copy to the Mac Mini (D-07)~~ **RESOLVED 2026-08-18** — operator copied library-db/ (15) and cover-scans/ (54) to `data@datas-mac-mini:~/archive/music-pre-project`, verified 54/54 sha256 + 15/15 integrity_check. Left in place as a hazard note: that host's non-interactive ssh PATH lacks `head`/`basename`/`sqlite3`, which produced two false "all 15 databases corrupt" results before absolute tool paths were used.
- 01-03: a duplicated audio_md5 makes the diff join last-wins, so in Phase 7 (BEFORE holds both backlog copies, AFTER holds one import) tag differences between duplicate sources are invisible. DUPE-01 should be resolved before QUAL-02 is treated as complete. The diff always lists such pairs in its informational section.
- 01-03: unsorted WAV content is NOT tag-free - all 40 sampled Now! 120 WAV records carry 6 format tags (title/artist/album/track/date/comment) plus an embedded cover-art stream. Plan 01-04 and Phase 7 must not assume an empty before-state for unsorted's 134 WAV files.
- 01-07: the manual beets container is NOT inert — its BEETSDIR config.yaml is a docker-compose file, so beets ran on defaults and left 47 items / 1.4 GB of WAV in /config/Music/__/. Phase 4 must account for it, plus a fifth latent entry point at beets/config/beets.sh.
- OPEN/UNOWNED: /mnt/tank/media/TV is 114,218 entries on orphan gid 545, the same gid 01-08 normalised Music away from. Out of scope, no requirement covers it, and it will hit the identical chown-from-LXC-100 EPERM. Leaving Music and TV divergent may be worse than leaving both wrong.
- ~~BLOCKING 2026-08-31 (02-01 Stage 0): atlantis is mid-incident on the documented amdgpu_hmm_invalidate_gfx NULL deref~~ **RESOLVED 2026-08-31 18:48:08** — rebooted via sysrq s+b; io pressure full avg300 96.22 -> 0.59, zero amdgpu_hmm_invalidate_gfx events this boot, taint 4225 (P+D+O) -> 4097 (P+O), both zpools ONLINE, 102 containers running, LXC 100 sshd normal. Root cause was NOT compaction: a Jellyfin VAAPI transcode started 07:56:56 and the kernel oopsed at 07:56:58. VAAPI disabled (encoding.xml HardwareAccelerationType=none, backup encoding.xml.bak.20260831T182741Z, scripts/disable-jellyfin-hwaccel.sh, commit b1ad9c1). **The correction that survives:** the July 2026 mitigation (THP=never + vm.compaction_proactiveness=0) was fully applied and did NOT prevent the recurrence, so the project-memory entry reading as "resolved" is wrong and should be corrected to name VAAPI as the trigger.
- BLOCKING for 02-06/02-07 (02-01 Task 3): the estate runs **Music Assistant (BETA) 2.11.0b0**, slug `d5369777_music_assistant_beta`, `auto_update: true`. The **stable add-on is not installed at all**. D-21 requires the phase be proven against stable — that cannot be satisfied as written. Operator must choose: install stable alongside, migrate off the BETA, or accept the BETA and stamp every criterion `2.11.0b0`. Auto-update on a beta channel means the stamped version can move before Phase 7. Does NOT block 02-03 (server-side only).
- BLOCKING for 02-06 (02-01 Task 3 measurement 5): D-30's provider enumeration is **unmeasured**. MA has an admin account (`onboard_done: true`; `auth/login` returns "Invalid username or password") but **no credential for it is recorded anywhere** — not `~/.claude/secrets/`, not `/mnt/fast/secrets/` on LXC 100. MA 2.11 gates `config/providers` behind scope `config.providers.read` and exposes only five unauthenticated commands. Three off-ramps measured closed: no `/addon_configs` entry for MA, no docker socket in the SSH add-on, `homeassistant` login provider `requires_redirect: true`. Obtain the credential and mint the D-39 token BEFORE adding any provider, so the baseline is taken against an untouched library.
- CORRECTION for 02-03 (02-01 Task 2): **never run a bare `terraform apply`.** The D-17 gate returned exit 2 with `Plan: 2 to add, 1 to change, 1 to destroy` and `proxmox_virtual_environment_container.selfhost must be replaced` — that is LXC 100, the Docker host with ~102 containers. Cause was a bpg/proxmox 0.95.0 artefact (33 mount_point blocks diffing `mount_options = [] -> null`, each forces-replacement) plus one real drift (`mpe_memory_mb` 20480 vs a host running 8192). Remediated in 1588f19 + 3051695; bare plan is now 1 add / 0 change / 0 destroy with zero forces-replacement. 02-03 must `terraform plan -out=`, read it, assert exactly `null_resource.nfs_music_export` and zero destroys, then apply the saved plan.
- CORRECTION for 02-04 (02-01 Task 3 measurement 6): **Jellyfin's t3_proxy address is 192.168.90.25, not the 192.168.90.31 pinned in 02-01 and 02-04** — the pin is wrong today, not merely fragile. Two further traps: the bare Docker DNS name `jellyfin` resolves to **Cloudflare's public edge** from the LXC 100 host because of `search deercrest.info` in /etc/resolv.conf (a health check would silently pass against the public site while the container was down), and `172.16.1.76` is unreachable from LXC 100 by macvlan host-to-container isolation despite working from the LAN. Use runtime resolution: `docker inspect jellyfin --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}'` — verified 200, no IP literal.
- CORRECTION for 02-03/02-05 (02-01 Task 3 measurement 7): **`showmount` and `findmnt` are both ABSENT on the NUC.** `nfs-music-export.tf`'s `verify_commands` output suggests `showmount -e 172.16.1.158` "from the HA NUC" — that line will not run; use `exportfs -v` on atlantis. Criterion 1e's `findmnt` proof of NFSv4 negotiation needs `/proc/self/mountinfo` instead (verified readable from the SSH add-on; its fstype column is where `nfs4` will appear). `sha256sum` and `nc` ARE present, so D-11's read-through hash is sha256.
- LATENT, suppressed not fixed (02-01 Task 2): `bpg/proxmox 0.95.0` plans a replacement for any container carrying `mount_point` blocks. `ignore_changes = [mount_point]` now silences it on both LXC resources, which means **real bind-mount edits to lxc-selfhost.tf / lxc-mpe.tf will plan clean and do nothing**. Bind-mount changes are a deliberate manual act (`pct set` / edit `/etc/pve/lxc/<vmid>.conf`, then reconcile) until the provider is upgraded. Trade-off documented in both files.
- ~~02-05 MUST re-test M1 from the client side~~ / ~~02-05: M1 (the mountpoint export option) is STILL UNPROVEN~~ **RESOLVED 2026-09-01 by 02-08 — M1 IS PROVEN, and the earlier readings were an INSTRUMENT ERROR, not a defect.** A discriminating client-mount pair from the NUC, same command minutes apart: dataset **mounted** → `mount -t nfs4` exit 0, 14 entries; dataset **unmounted** (`zfs unmount`, no `-f`, behind a dead-man restore) → exit 255, `failed: No such file or directory`, 0 entries. The `mountpoint` export option genuinely makes `rpc.mountd` refuse. `exportfs -v` printed the **identical line in both states** — the export *table* is non-discriminating while the *served mount* is refused, which is exactly why three plans read this wrong. The control was run first, with the dataset mounted, so a later failure could only mean refusal rather than incapacity. **02-03's `threat_flag: control-not-enforced` on `infra/nfs-music-export.tf` is RETIRED**; the measurement now lives in the file itself (`a4174e6`). Do NOT remove `mountpoint`. M2 (`After=zfs-mount.service`) remains the boot-race guard; M1 is a proven second layer. *Why the earlier probes failed:* they ran as `sysadmin` without `sudo`. The HAOS SSH add-on has `sudo` `NOPASSWD: ALL`, `CapBnd` with `CAP_SYS_ADMIN`, and Protection mode already off — it was never privilege-limited.
- ~~02-05: check-music-consumers.sh is STILL not on LXC 100 and a git pull there CANNOT land it~~ **RESOLVED 2026-09-01** — the 41 local commits were pushed to `origin/main` with explicit operator approval (`aa2b502..90cdddc`, clean `git pull --rebase`). `git pull --ff-only` in `/mnt/fast/stacks` now lands the script; both of 02-08's audit gates ran from a pulled copy at HEAD `90cdddc`, exit 0. The `scp` workaround is retired and **02-09's `quick-health-check.sh` fold-in has a real pull path.**
- **02-08 — an HA trigger that has never fired is not a detector.** D-54a was built, its delivery path validated (notify service registered, templates render), and it was still **structurally unable to fire** on the one scenario it existed for. Two generalisable rules came out of it: (a) `numeric_state` fires on a **crossing** and is armed only by a prior non-matching change, so it cannot catch a fault that was already true when HA started — and a `state: to: <value>` trigger cannot either, because the entity lands on its boot value **6–15 s before the automation attaches** (measured on four HA starts) and an unchanged poll fires no event. Only `homeassistant` `event: start`, which fires **at attach time**, can catch a pre-existing fault. (b) Put the debounce in the **action** (`delay` + re-read) rather than `for:` on the trigger: `for:` leaves no trace that the trigger ever armed, which is how this hid for a plan and a half.
- **OPEN (02-08): D-54b is blind at boot — an ordering, not a race.** `automation.music_supervisor_raised_a_system_issue`'s trigger is correct (a synthetic `repairs_issue_registry_updated` event fired it in 542 ms). It still misses every boot-time Supervisor issue, because HA's `hassio` integration mirrors those issues into the repairs registry **~13–18 s before the `automation` domain sets up** — identical across four observed HA starts, so it misses every time rather than sometimes. Evidence: a genuine `{action: create, domain: hassio}` event at `12:51:53.032Z` vs the trigger attaching at `12:52:21.951Z`. **Not fixed deliberately:** closing it needs a `command_line` sensor against `http://supervisor/resolution/info` with `$SUPERVISOR_TOKEN`, which for the only issue type in scope would duplicate `music02_nfs_mount_failed_alert` (now boot-covered) and, scoped wider, would page repeatedly for pre-existing issues nobody has chosen to act on.
- 02-05: ACCEPTED CONSEQUENCE (D-27/T-02-21) — Route A's usage:media also surfaces the music library in Home Assistant's own Media browser to anyone with HA access. Measured: HA Core reads the same 13 artist directories. Accepted: usage:media is what makes Route A work, the mount is ro on both client and export, and the audience already has HA access. Belongs in PROJECT.md per D-47.
- **BLOCKING FOR PHASE 7 (02-07): `missing_album_artist_action: folder_name` is CONDITIONAL, and a configured value is NOT a firing value.** Measured with a 4-cell variant matrix on a throwaway export: the fallback uses the artist folder name ONLY when the file's `album` TAG agrees with its album FOLDER name (year suffix ignored). On a mismatch MA silently uses `Various Artists` — while `config/providers/get` reads back `folder_name` throughout, so the API cannot tell you it did not fire. The track artist tag is irrelevant (a decoy artist still produced the folder name; an agreeing artist did not rescue a mismatched album tag). MA's own sync log (`tasks/log`) is the ONLY instrument that names which branch fired — `using foldername X as fallback` vs `using Various Artists as fallback`. Album identity is `albumartist + os.sep + album`, so a wrong album artist is a DURABLE entry and the only cheap repair is removing and re-adding the provider, which drops every favourite and play count attached to its items.
- **OPEN, recorded not repaired (02-07): `/mnt/tank/media/Music/Def Leppard/Def Leppard (2015)/` derives an EMPTY album artist and hard-errors one file** (`CD 01-06 Def Leppard - Sea of Love.flac`), because the album folder name equals the artist folder name — MA's derivation appears to lock onto the top-level `Def Leppard` directory as the album folder, whose parent is the provider root. Two files hit it; one errored. **No remedy was attempted and none is available here:** D-05 makes tag repair the wrong remedy on principle and the `ro` export makes it unavailable in fact. `zpool status -v tank` is clean, so this is NOT 2026-07 scrub damage. Phase 7 meets this at scale.
- **CORRECTION for anything querying MA albums (02-07): `search` on `music/albums/library_items` is NOT a substring match.** Searching an album's OWN EXACT NAME returned `[]` while a one-word prefix returned that same album, from the same provider, in the same second (`Mastermix Essential Hits - Pop 4 - 2005-2009` vs `Mastermix`). Short names happen to work, which is what makes it dangerous. Filter on `provider` ONLY and do the exact comparison locally — otherwise the gate reports `no exact match … candidates were: <none>`, indistinguishable from the album being genuinely absent. Fixed in `check-music-consumers.sh` (`ed1d367`).
- **CORRECTION for any future Terraform teardown (02-07): destroying a `null_resource` removes NOTHING from the host.** `music_temp_export_enabled = false` was not a teardown — the drop-in file stayed on disk and the export stayed live while `terraform plan` reported clean. Fixed by an always-present reconciler resource (`d7430ee`). **A destroy-time provisioner is NOT an option here:** `terraform validate` refuses one whose connection block reads variables, and the only workaround carries the Proxmox root password in `triggers` — plaintext state plus every plan diff, in a public repo. `self.triggers.*` is also unsafe at destroy time: it reads from STATE, so a key added after creation reads null and `grep -q ""` matches every line.
- ~~⏱ TIME-SENSITIVE (02.1-01, 2026-09-02): / on LXC 100 has 185 MiB of margin over the D-17 floor (20.18 GiB avail vs 20.00 GiB), and Jellyfin's transcode cache has already refilled to 12.55 GiB / 1,324 files at roughly 6 GiB/day.~~ **MATERIALLY REDUCED 2026-09-02T22:19:52Z by 02.1-05's cutover, but NOT cleared.** New transcode writes now land on `fast/transcode` under a 50 G quota, so **`oldvol_transcodes_bytes` is a FROZEN stock rather than a growing one** — the ~6 GiB/day clock has stopped and the "budget measured in hours" framing no longer applies. Margin is now ~216 MiB, the widest all phase, because the recreate was `/`-positive. **Two reasons it is not cleared:** (1) the 12.55 GiB is still *on* `/` and is only released by **02.1-06's `docker volume rm`**, which should not be left sitting; (2) the margin still erodes a few MiB per half-hour from ordinary churn across the other 78+ containers. **If `oldvol_transcodes_bytes` ever moves again, that is not the old problem continuing — it is `jellyfin.yaml` having been reverted, and the standing check's section 2 is the alarm.** The operator decision point in 02.1-01's rollback table (moving 02.1-09's reap earlier) still stands if a D-32 sample reads below 21474836480.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Duplicates | DUPE-01, DUPE-02 | v2 — before any `unsorted` import | 2026-08-17 |
| Bucket B | NOWB-01, NOWB-02 | v2 — manual confirmation budget | 2026-08-17 |
| Acquisition | LIDR-01 — replace Lidarr as grabber | v2 — wanted; WRIT-03 removes the harm now | 2026-08-17 |
| Bucket C | DJCC-01 – DJCC-05 | v2 — lowest-confidence research area | 2026-08-17 |

## Quick Tasks Completed

| ID | Task | Date | Status |
|----|------|------|--------|
| 260826-0u0 | Document Tailscale configuration and low-level design across all systems | 2026-08-26 | complete ✓ |
| 260901-u96 | Read-write NFS export on atlantis for Home Assistant backups (external RES-04) | 2026-09-01 | complete ✓ |
| 260902-fxf | Refresh keeper-sh docs against live state, add keeper-mcp service, relocate misfiled Innofactor docs | 2026-09-02 | complete ✓ |
| 260902-gln | Document who gets reminders for Keeper-created events; plan the Work-calendar split | 2026-09-02 | complete ✓ |
| 260902-hya | Complete the keeper-sh .env.sample and correct the compose description comment | 2026-09-02 | complete ✓ |

## Session Continuity

Last session: 2026-09-02T22:35:00.000Z
Stopped at: Completed 02.1-05-PLAN.md
Resume file: None

**02-09 IS COMPLETE AND THE PHASE IS CLOSED.**

Machine gate green three ways: `check-music-consumers.sh` **0** (FAILURES 0, `--baseline` 0,
`--bogus` 2), `check-music-freeze.sh` **0**, `quick-health-check.sh` **0** with both blocks green.
`terraform plan -detailed-exitcode` **0**. All five ROADMAP criteria have an explicit verdict with
named evidence in `02-09-SUMMARY.md`, including criterion 1's five sub-parts individually.

**D-55 APPROVED, verbatim:** *"i have spot checked a couple and played them to make sure the song
matchs - all good, no various artists, no singles . mastermix is not there"*

**The lesson worth carrying:** the operator **played tracks**. Every automated check in this phase
verifies that MA's **database** says the right thing — album name, album artist, provider
attribution — and none of them can verify that the **bytes behind the entry are the right song**.
The stale state this phase spent two plans characterising is exactly *"entries exist, playback of
any of them fails"* — 70 albums, all unplayable, every database assertion still passing. **Playback
is the only test that closes that, and it is not automatable from here.** D-55 earned its place.

**⚠ Do NOT push without asking.** **5 commits ahead of `origin/main`** — `a4174e6` + `6ff2332`
(02-08) and `9f915a9` + `e37039b` + the 02-09 close. `/mnt/fast/stacks` on LXC 100 is still at
`90cdddc`, so it does not yet carry the folded-in `quick-health-check.sh` — which does not matter,
because that script runs from the workstation.

---

**02-08 IS COMPLETE. All three tasks ran, plus a fix for the defect the live test found.** The
record is `02-08-SUMMARY.md`; `02-08-PARTIAL.md` has been folded into it and removed, so there is
one record, not two. **CONS-03 is ticked and earned** — the reboots were the only thing 02-07 was
missing, and they happened.

**The one-paragraph version of what the phase learned here:** a green result on the positive reboot
was never going to mean anything, and it did not — atlantis was healthy so the race was never
exercised. The negative control is what paid: it reproduced the failure exactly as predicted, proved
MA's deletion guard preserves rather than purges, settled unattended recovery at **432 s**, and
**found a detector that was structurally unable to detect the thing it was written for**. That last
one is the output worth having.

**Read `02-08-SUMMARY.md` before 02-09.** Four things in it change what a later plan may assume:

1. **`mount | grep emergency/music` can never match on this Supervisor version.** There is no
   `/emergency/` bind. Supervisor makes the media directory read-only **in place** and leaves it
   empty. The working proof line is `/media/music` present, `dr--r--r--`, root-owned, 0 entries.

2. **`exportfs -v` cannot tell you an export will serve.** It prints the line whether or not
   `rpc.mountd` will honour it. This is how M1 was mis-recorded as unproven for three plans.

3. **The default `ha supervisor logs` depth does not reach back to boot.** A default-depth grep
   returns nothing and looks exactly like "it did not happen". Use `-n 2000` or deeper.

4. **The HAOS SSH add-on is not privilege-limited.** `sudo` is `NOPASSWD: ALL`, `CapBnd` carries
   `CAP_SYS_ADMIN`, Protection mode is already off. Two earlier probes were recorded as blocked by a
   privilege limit; they were blocked by a missing `sudo`.

**A new long-lived MA token exists**, named `HA M4 music sync (phase 02-08)`, 1 year, held ONLY as
`ma_ha_sync_authorization` in `/config/secrets.yaml` on the NUC — never in this repo (asserted six
ways). **Correction to 02-04's record: MA 2.11 DOES have a token API** (`auth/token/create` /
`auth/tokens` / `auth/token/revoke`); it has no token *UI*. That also means the audit script's
log-in-per-run pattern, which has now accumulated 99 `WebSocket Session` rows against a 100-row
response cap, could become a named revocable token — **logged for 02-09**.

**Also logged for 02-09:** carry the corrected HA YAML into `beets.md` (D-47) — the SUMMARY holds it
verbatim; the `Xonora` token (created 2026-02-21, expiring 2036, unused since March, unattributed)
belongs in the project-close rotation alongside the Discogs token; and D-54b's boot blind spot is
open with its specific fix recorded.

**02-07 is complete. CONS-02 is ticked and criterion 3 is proven** (CONS-03 was correctly left for
02-08's reboots). Three albums,
exact on album name AND `artists[0].name`, provider-attributed, inside a 177-second deliberate
`music/sync`. `check-music-consumers.sh` exits **0** in steady state and `check-music-freeze.sh`
exits 0 with FAILURES 0, byte-identical to 01-09's closure. Nothing was written into
`/mnt/tank/media/Music` at any point: 2,674 entries, 33.9 G, zero files newer than the plan start,
asserted three times.

**The control FAILED before it passed, and that is the phase's most valuable output** — see the
`folder_name` blocker under Blockers/Concerns before planning Phase 7. Two instrument defects were
also found and fixed: MA's `search` argument produced a false FAILURE, and the temporary export's
teardown produced a silent PASS.

**The PARTIAL naming convention is still the rule for halted plans.** `phase-plan-index` treats any
`*-SUMMARY.md` as plan-complete on file existence alone, regardless of its `status:` frontmatter — so
a halted plan's record must be `-PARTIAL.md` and only becomes `-SUMMARY.md` when the plan genuinely
finishes.

Next in phase 2: **02-09**, the last plan. Read 02-08's SUMMARY and 02-07's blockers first — the
`folder_name` precondition is the one that changes what Phase 7 has to check, the
`Def Leppard (2015)` empty-album-artist case is a live example of it, the audit script now lands on
LXC 100 via `git pull` (the `scp` workaround is retired), and MA is still BETA `2.11.0b0` with
`auto_update: true`, so stamp the version on every assertion.

**D-45's rollback assertions have now been executed once against real state** (02-07 Task 3), so
02-09's runbook documents a tested procedure — including the part that did not work as authored.

**Two hazards carried from 02-05 for anyone touching the export.** `ssh -n` points stdin at
`/dev/null`, so `ssh -n host 'bash -s' <<EOF` silently discards the entire script and exits 0 — use
`-n` for inline `ssh host 'cmd'` only. And `/proc/fs/nfsd/exports` shows four `no_root_squash` hits
once a client mounts; they are auto-generated `v4root` traversal entries, not a T-02-06 regression.
Assert `no_root_squash` on `exportfs -v` — but **never assert export *health* on `exportfs -v`**:
02-08 measured it printing an intact line for an export that refused every client. The only
export-health check that means anything is a real client mount attempt.

Plans 01-02, 01-04, 01-06, 01-07, 01-08 and 01-09 are `autonomous: false` — they carry blocking
human checkpoints (the fence run, the ~140 GB capture, the Lidarr/Jellyfin freeze and its one-hour
watch, the beets config vendoring, the recursive chown, and the phase-closure verdict).

Next: `/gsd-plan-phase 2 --research-phase`
