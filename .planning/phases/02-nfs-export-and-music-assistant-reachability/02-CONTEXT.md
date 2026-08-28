# Phase 2: NFS Export and Music Assistant Reachability - Context

**Gathered:** 2026-08-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Music Assistant reads the same tagged tree as Jellyfin, over a read-only NFSv4 export served from
the Proxmox host and defined in `infra/` Terraform — proven on three already-correct albums under
the correct album artist, and surviving a NUC reboot, **before any content flows**.

Delivers: CONS-01, CONS-02, CONS-03.

**Not in this phase:** choosing or configuring a tagger (Phases 3/4/6); building the `_inbox`
structure (Phase 5); importing content (Phases 7/9); CONS-04's per-file import verification
(Phase 7 — though this phase builds the *tooling* CONS-04 will call). Closing the macOS/SMB writer
found in 01-06 is a WRIT-class change and stays out (D-32).

**This phase adds a reader and changes no content.** Nothing here writes to `/mnt/tank/media/Music`.

**Note on ordering:** `02-RESEARCH.md` already exists (written before this discussion, 114 KB) and
resolved most technical questions from primary sources. The decisions below either **confirm** its
recommendations or **decide the things it explicitly flagged as needing user confirmation**
(A8, A11, Open Questions 1–5). Where a decision below contradicts nothing in the research, the
research's detail stands as the implementation guide.

</domain>

<decisions>
## Implementation Decisions

### Album artist and the `folder_name` fallback

- **D-01:** MA's `missing_album_artist_action` is **`folder_name`**, not the `various_artists`
  default. Because the target tree is `ALBUMARTIST/Album/NN Title`, `folder_name` and a correct tag
  **agree** when the tag is present and **disagree loudly** when it is absent. The MA default is a
  trap for this library specifically: it is heavy on DJ compilations that legitimately *are* Various
  Artists, so a missing tag would produce an entry indistinguishable from a correct one.
  (Resolves research A11, flagged `[ASSUMED — reasoned, needs user confirmation]`.)
- **D-02:** The choice is **permanent**, recorded in PROJECT.md as a Key Decision — not a
  pilot-only setting. Once the tagger owns the tree the path contract is permanent, so a
  folder/tag disagreement is always a real defect worth surfacing. Same reasoning as Phase 1's
  D-17 Jellyfin-freeze permanence: nothing to remember to undo.
- **D-03:** The fallback is **proven to fire**, not merely configured. A deliberate control album
  with no `albumartist` is scanned and the fallback observed. Without this, the setting ships
  unverified and its first real exercise is the Phase 7 pilot at scale.
- **D-04:** The control lives on a **second, temporary export + second MA provider** pointed at a
  scratch directory under `tank/downloads` — never inside `/mnt/tank/media/Music`. Honours
  CLAUDE.md's "never stage untagged content under `/media/Music`", keeps the library tree untouched,
  and exercises the MA provider add/remove path — knowledge Phase 7 needs.
- **D-05:** If any of the three albums appears under the **wrong album artist**, criterion 3 fails
  and the phase **halts for diagnosis** — but the remedy is **never tag repair**. Nobody holds `rw`
  on Music until Phase 6 (Phase 1 D-20) and the export is `ro`. The remedy is either swapping in a
  genuinely-correct album (recording the reject) or fixing MA-side config. Tag repair is Phase 6/7.

### The three proof albums

- **D-06:** The three are **one single-artist album, one multi-disc release, and one legitimate
  Various Artists compilation**. MA's album identity is `albumartist + os.sep + album`, so this
  exercises the identity key in all three shapes rather than only the easy one — and anticipates
  QUAL-03's "include the historically painful cases" one phase early, at negligible cost.
- **D-07:** They are **selected from Phase 1's QUAL-01 `ffprobe` NDJSON snapshot** and their
  correctness is **pre-verified before use as the gate** (`albumartist` non-empty, folder name
  agreeing with the tag). If a bad tag and a bad mount are both possible, an MA failure is
  uninterpretable — pre-verification makes any failure unambiguously MA's or the export's.
- **D-08:** If the 13-folder / 1,244-file library contains **no multi-disc release or no legitimate
  VA compilation**, substitute a correctly-tagged release from the backlog via the **same second
  temporary export from D-04**. The shape gets exercised rather than silently skipped.
- **D-09:** The three are **pinned in `scripts/check-music-consumers.sh`** — path, expected
  `albumartist`, expected album, keyed on the QUAL-01 `audio_md5` — and the **same three** are
  re-asserted after the positive reboot, after the negative control, and again by Phase 7's
  CONS-04. One canonical, machine-checkable set.
- **D-10:** The assertion is an **exact match** of MA's returned album `name` and `artists[].name`
  against the snapshot's `album` and `albumartist`. "An album appeared" is the *files are visible*
  gate the roadmap explicitly rejects, and it would pass on a `folder_name` or `various_artists`
  fallback entry.
- **D-11:** Criterion 3 additionally requires **bytes read through the mount**, not just a library
  entry. The documented stale state is precisely *"entries exist, playback of any of them fails"* —
  an MA entry can be a survivor from before the mount broke. Proof is a **plain file checksum taken
  on atlantis and again through the NUC's mounted path, required to match**. Deliberately *not*
  `ffprobe` on the NUC (HAOS busybox almost certainly lacks it — research A13) and deliberately not
  MA playback (adds player/codec failure surface unrelated to the export). The QUAL-01 audio hash
  still identifies *which* files; the plain hash proves they arrive intact.

### The export itself (server side)

- **D-12:** Confirmed as recommended by research: `/mnt/tank/media/Music` exported to
  **`172.16.1.31` only** with `ro,all_squash,anonuid=568,anongid=568,mountpoint,no_subtree_check,sec=sys`,
  written to `/etc/exports.d/music.exports`. This is CLAUDE.md's **Option B**, forced by ROADMAP
  C-9 (the export inherits Phase 1's WRIT-04 value).
- **D-13:** **The tailnet address `100.73.196.51` is NOT in the export line.** Traffic the NUC
  originates toward `172.16.1.158` egresses its LAN interface with source `172.16.1.31`; NFS never
  crosses the tailnet in this design; adding it would widen the blast radius for nothing. Recorded
  as a decision so it is not re-litigated. If off-LAN mounting is ever needed, that is a deliberate
  new export line, not a pre-emptive one.
- **D-14:** `nfs-kernel-server` is installed by a **guarded install inside the same `null_resource`
  that writes the export** (`dpkg -s … || apt-get install`), so a re-apply is a no-op — which is
  what criterion 1's "clean re-apply" actually measures. The unit is **enabled** so it survives the
  host reboot that M2's ordering drop-in is written for.
- **D-15:** The **second (temporary) export is also Terraform-managed**, behind an explicit
  enable variable defaulting to **off**. Teardown is `terraform apply` with the flag off — provably
  gone rather than forgotten. A hand-run `exportfs` would drift the host from `infra/`, which
  CLAUDE.md C-1 forbids and which would make "a re-apply is clean" meaningless.
- **D-16:** Scope stays **Music only**. Movies/TV, additional clients, and a generalised export
  module are out — CONS-01 says "the Music dataset, restricted to the NUC", and each addition
  widens what a `ro` export exposes. The D-15 enable flag already demonstrates the pattern extends.

### Stage 0 preconditions (all blocking)

- **D-17:** **`terraform plan` must be clean before `infra/` is touched.** Pre-existing drift would
  otherwise be swept into this phase's apply — reverting unrelated host config while adding an
  export — and criterion 1's "a re-apply is clean" becomes unmeasurable. *(Raised by the operator
  mid-discussion; this estate has a documented Renovate deploy-drift problem and `infra/` carries a
  committed `terraform.tfstate`.)*
- **D-18:** If the plan is **not** clean: **blocking operator checkpoint** with the plan output
  presented. Reverting drift on a host running 78+ containers is not an autonomous decision, and
  the drift may be deliberate. The operator chooses: reconcile, update the code, or accept and
  switch to a targeted apply.
- **D-19:** Probe **`exportfs -v`, `/etc/exports`, `/etc/exports.d/*`, and `zfs get -r sharenfs tank`**
  before Stage 1. **Any existing export or non-`off` `sharenfs` is a blocking checkpoint** — two
  export tables for one path is a silent-misbehaviour bug, and `exportfs -v` alone cannot tell you
  which one a client is actually getting. (Research A2, medium-high risk.)
- **D-20:** **Measure the NUC's source address, don't assume it.** From the NUC, determine the
  source address on the route to `172.16.1.158` and confirm it matches the export line. NETWORK.md
  says `.31`, but the NUC is *also* a subnet router for `172.16.1.0/24` with a tailnet interface —
  exactly the topology where a source address surprises you, and a denied mount is otherwise
  indistinguishable from a dozen other faults. (Research A5, high risk.)
- **D-21:** **Confirm which MA add-on is installed** (`ha apps --raw-json` + MA's `/info`) rather
  than assuming 2.9.13 stable. 2.10 changes the NFS provider's subfolder handling — Route B's very
  ground — and adds a `scan_errors.incomplete` guard. Prove the phase against **stable**, and record
  the **exact version every criterion was proven at**. (Research A7.)
- **D-22:** **Re-verify the HAOS access path at Stage 0** — `ha` CLI over SSH with the `bash -lc`
  wrapper, SSH add-on protection mode **off** (last confirmed 2026-07-27). `unauthorized` is trivial
  to fix in the add-on UI but expensive to discover mid-reboot-test. Protection mode **stays off**;
  the audit script folded into `quick-health-check.sh` depends on this path continuing to work.
  Drive HAOS through the `~/.claude/skills/ha-deercrest` patterns rather than re-deriving them.

### Route A, Route B, and the fallback trigger

- **D-23:** **Route A** — `ha mounts add music --type nfs --usage media --server 172.16.1.158
  --path /mnt/tank/media/Music --read-only`, then an MA **"Filesystem (local disk)"** provider at
  `/media/music`. Confirmed by the MA maintainer in discussion #1198. Route B is the pre-specified
  fallback.
- **D-24:** **The fallback trigger is narrow**: switch to Route B only if `ha mounts add` cannot
  reach `state: active` after Supervisor's retry, **or** the write-attempt test fails to be refused
  through the Supervisor mount. Those are the only two things Route B changes. An `albumartist` or
  sync problem is **not** a Route A failure — it would reproduce identically on B, and switching
  would waste the phase chasing the wrong layer.
- **D-25:** **If Route B wins, the reboot work is re-characterised, not reused verbatim.** Route B
  mounts inside the MA container, so Supervisor's emergency empty-directory bind — the entire
  documented failure mode — cannot occur, and `mount | grep emergency/music` is not available as a
  proof line. The plan must state what the B-side evidence *is*, or the negative control tests a
  failure mode that cannot happen and passes vacuously. Both controls still run.
- **D-26:** **Mount name is `music`** (Supervisor rejects hyphens outright), and before mounting,
  **assert `/media/music` is absent or empty**. A non-empty target degrades the mount silently into
  a path that looks correct and isn't — the same invisible class of failure as the emergency bind.
- **D-27:** Route A's `usage: media` **also surfaces the library in Home Assistant's own Media
  browser**, playable by anyone with HA access. This is **accepted and recorded as a known
  consequence**: `usage: media` is what makes Route A work and Supervisor offers no finer-grained
  usage; the mount is `ro`; the audience is household members who already have HA access.

### Provider configuration and identity

- **D-28:** The provider's **`content_type` must be `music`** — MA's `missing_album_artist_action`
  entry is `depends_on=CONF_CONTENT_TYPE, depends_on_value="music"` and will not apply otherwise.
- **D-29:** After setup, **read the whole provider config back** via `config/providers/get` and
  commit it as evidence — `content_type`, `missing_album_artist_action`, path, instance id. The
  provider becomes reproducible if MA is rebuilt, drift becomes a visible diff, and the audit script
  gets its expected values. MA's defaults have already proven to be a trap once in this phase.
- **D-30:** **Every assertion filters by the provider *instance id*, not the display name** (which
  is user-editable in the GUI). Also **enumerate MA's existing providers at Stage 0** and record
  them — an album matching from Spotify must not be able to pass a test about an NFS export.
- **D-31:** **Provider creation:** run the `/api-docs/commands.json` discovery step first (served
  unauthenticated, enumerates every command with its argument schema). If the setup flow can be
  driven headlessly, do it. If not, create the provider via the **GUI once** — and keep everything
  downstream (`config/providers/save`, `music/sync`, `music/albums/library_items`) headless, since
  those are confirmed. (Resolves research Open Q1.)

### Reboot resilience

- **D-32:** **Both controls are in scope.** A NUC reboot with atlantis healthy does not exercise the
  race at all — criterion 4 would pass by luck. The negative control runs: stop `nfs-server`, reboot
  the NUC, capture the evidence the emergency path fired, then **wait out Supervisor's ~900 s reload
  to prove unattended recovery**. That wait is the half the conflicting community reports dispute,
  and this is the only way to settle it on this estate at this version.
- **D-33:** **M1 + M2 + M3 + M4 are all built.**
  - **M1** `mountpoint` on the export — a host reboot where `nfs-server` starts before `zfs-mount`
    then exports *nothing* rather than the empty stub under the unmounted dataset. Free, and in
    neither of CLAUDE.md's candidate option sets.
  - **M2** `After=zfs-mount.service` drop-in for `nfs-server.service`. Must be `After=`/`Wants=` —
    ZFS mounts are not systemd `.mount` units, so `RequiresMountsFor=` will not resolve.
  - **M3** rely on Supervisor's 900 s reload for self-healing (upstream's designed behaviour).
  - **M4** HA automation on `homeassistant_started` → wait 120 s → call MA sync, collapsing
    staleness from ≤12 h to ~2 min.
- **D-34:** **M4 is gated on a verified `rest_command`.** MA exposes no sync service to the HA
  integration, so it must be a `rest_command` to MA's `POST /api` — research flags this as
  unverified. Verify it works **before** building the automation. Its token lives **only** in
  `/config/secrets.yaml` on the NUC referenced as `!secret`, never in this repo (CLAUDE.md C-7),
  and is a **separate token** from the audit script's. If the `rest_command` does not work, M4
  becomes a deferred idea rather than stalling the phase.
- **D-35:** **The atlantis reboot is simulated, not performed.** `systemctl stop nfs-server` →
  `zfs unmount tank/media/Music` → `systemctl start nfs-server` → assert `exportfs -v` shows nothing
  for that path (M1 working) → remount, re-export, re-assert. Proves the mechanism without taking
  the entire estate offline — and this host has an amdgpu history where a graceful reboot hung and
  needed sysrq.
- **D-36:** **The NUC reboot work is a blocking human checkpoint** (`autonomous: false`), matching
  Phase 1's convention for host-touching work. Rebooting the house's automation hub is the
  operator's call on timing, not the plan's.
- **D-37:** **Evidence is captured transcripts committed under the phase directory**, dated. The
  three proof lines the research names — `mount | grep emergency/music`, Supervisor's
  *"failed to mount, mounting read-only fallback"*, and MA's *"Aborting sync … scan found no files
  but N were previously indexed"* — **all three**, plus before/after album counts. Fewer than three
  means the negative control did not fire and the test proved nothing.
- **D-38:** **MA's `sync_interval` stays at the 12-hour default.** Criterion 3's "within one sync
  cycle" is satisfiable in seconds via `music/sync`; M5 (shortening it) is blunt and increases scan
  load on a 34 GB tree for a rare event. M4 already collapses the window for the case that matters.

### Credentials and the audit script

- **D-39:** The **MA long-lived token lives at `/mnt/fast/secrets/` on LXC 100**, `0600`,
  root-owned, **written via stdin** so it never enters the process list on a host running 100+
  containers. This mirrors Phase 3's D-04 Discogs pattern exactly — one convention for project
  secrets. **365-day lifetime; rotate at project close**, alongside the Discogs token, for the same
  reason (it will have passed through a conversation transcript).
- **D-40:** The **Jellyfin API key is newly minted and purpose-named** (e.g. `music-consumers-audit`),
  stored the same way. Phase 1 found `jellyfin-jellyfin.db` already carries an `ApiKeys` table with
  **4 admin-scoped rows** that nobody can attribute — reusing one inherits an unknown purpose and
  makes later rotation a blind risk.
- **D-41:** **`scripts/check-music-consumers.sh` ships in this phase and folds into
  `scripts/quick-health-check.sh`**, following Phase 1's D-29 precedent — harness drift gets caught
  on a path already in use. Read-only by contract, `--baseline` exits 0, matching
  `check-music-freeze.sh`'s exit-code convention.
- **D-42:** The script asserts **both consumers** — the same three albums via Jellyfin's API *and*
  via MA's — so Phase 7's CONS-04 ("visible in both Jellyfin and Music Assistant") has one script
  that answers the whole question, and this phase's blast-radius check has a real assertion rather
  than "Jellyfin looks fine".
- **D-43:** If **MA has no admin user** (research A8, high risk — unmeasured), the plan **completes
  MA's `/setup` at an operator checkpoint** and continues. MA is already installed and running in
  the estate; this is a one-off config gap, not new scope. Blocking here would stall Phase 7's
  CONS-04 too.

### Blast radius, rollback, and durable record

- **D-44:** **`scripts/quick-health-check.sh` runs as a before-snapshot and again after the export
  is live**, and Jellyfin is confirmed still reading `/media/Music`. CLAUDE.md C-6 requires the
  blast radius be *argued, not assumed*; a before/after on a check that already exists is the
  cheapest honest form of that argument, and the docker `created`-state blind spot is precedent
  that narrow checks miss things for weeks.
- **D-45:** **Rollback is a documented, tested teardown on both sides**: Terraform removes the
  export drop-in and `exportfs -ra` re-converges; `ha mounts remove music` on the NUC; the MA
  provider is removed. Nothing here writes content, so there is nothing to restore — the risk is
  leaving half a mount graph behind. **Reuses the same assertions as the D-46 temp-export teardown.**
- **D-46:** **Teardown of the temporary export asserts both sides are gone**: `exportfs -v` shows
  only the Music line, **and** MA's `music/albums/library_items` for that provider id returns
  nothing, **and** the provider is absent from `config/providers`. Watching MA's removal path work
  on one throwaway album is the cheapest possible place to learn a behaviour this whole phase exists
  to be careful about.
- **D-47:** **Criterion 5 record** — PROJECT.md gets the Key Decisions (winning mount route with the
  loser's failure symptom noted; PROJECT.md's current claim that HA storage config is the route
  corrected either way; `folder_name` permanence; the export line and why `mountpoint` is in it; the
  `172.16.1.31`-only / no-tailnet decision). Operational detail — mount commands, API assertion
  shapes, reboot evidence — **extends `stacks/selfhosted/arrs/beets.md`**, following Phase 1's D-30
  document-beside-the-stack pattern. MA runs as an HA add-on on the NUC, so there is no stack in
  this repo for it to sit beside.
- **D-48:** **NETWORK.md gets an entry** — atlantis:2049 serving `/mnt/tank/media/Music` `ro` to
  `172.16.1.31` only, cross-linked to the Terraform file. NETWORK.md is the repo's map of hosts, IPs
  and access methods; a new listening service between two of those hosts belongs on it. Follows the
  cross-linking pattern the Tailscale LLD established.

### Security posture

- **D-49:** **`xprtsec=` / RPC-with-TLS (RFC 9289) is CONSIDERED AND REJECTED.** It needs `tlshd`
  configured on both ends for a read-only, LAN-local music library, and MA itself documents that it
  adds no encryption or access control and assumes a local network. Recorded explicitly so the
  security gate has a reasoned answer rather than a silence. (Resolves research Open Q4.)
- **D-50:** **`sec=sys` with a single-host restriction is accepted and recorded**: any device that
  can present as `172.16.1.31` can read the library. Kerberos was considered — it would mean a KDC
  on this estate for one read-only music share, with unproven `sec=krb5` support on the HAOS side.
- **D-51:** `no_root_squash` remains **forbidden** (CLAUDE.md), and is moot under `all_squash`.

### Plan shape

- **D-52:** **Split at the server/NUC boundary.** Plan 1 is entirely atlantis — Stage 0 probes, the
  TF-drift gate, `nfs-kernel-server`, the export, M1/M2, and the D-35 simulated-unmount proof. It
  **satisfies CONS-01 on its own and is independently shippable**: a `ro` export nothing consumes
  yet is harmless and complete. Plan 2+ is the NUC/MA side. This mirrors Phase 4's deliberate
  independent-shippability principle and the roadmap's stated intent that a stall still leave the
  estate strictly better off.
- **D-53:** **Blocking operator checkpoints** are: the TF-drift branch (D-18), any Stage 0
  export/`sharenfs` hit (D-19), MA `/setup` if absent (D-43), the NUC reboot and negative control
  (D-36), and phase closure (D-55).

### Alerting

- **D-54:** **Add an HA notification** on Supervisor's `MOUNT_FAILED` repairs issue. The estate has
  a history of things being silently down for long periods (dispatcharr/teleport six weeks;
  podsync's yt-dlp thirteen months), and an exit code nobody reads is not detection. HA is already
  on the NUC and already raises the issue; this pairs naturally with M4's automation and may be one
  config addition rather than two.

### Verification

- **D-55:** **Closure gate is the script verdict *plus* the operator opening Music Assistant** and
  seeing the three albums under the right artists. `check-music-consumers.sh` exiting 0 is the
  machine gate; criterion 3 is ultimately about what a person sees, and this project exists because
  pipelines were declared working and weren't. Matches Phase 1's `autonomous: false` closure-verdict
  convention.
- **D-56:** **MA add-on auto-update stays ON.** The operator chose currency over pinning. **This
  makes `check-music-consumers.sh` load-bearing rather than a nicety** — it is the only mechanism
  that would catch an MA release changing provider behaviour under the pipeline. The planner should
  treat the script's correctness and its inclusion in `quick-health-check.sh` accordingly, and the
  recorded decision must still name the exact version every criterion was proven at (D-21).

### Claude's Discretion

- Exact scratch-directory naming under `tank/downloads` for the temporary export, Terraform variable
  and resource naming, and the `exports.d` filename.
- Script internals, function decomposition, and output formatting for
  `scripts/check-music-consumers.sh` — subject to the read-only contract and the
  `check-music-freeze.sh` exit-code convention (D-41).
- Task ordering within each plan, and whether Stage 0's probes are one task or several.
- The precise checksum algorithm for D-11's read-through proof.
- Whether the HA notification (D-54) and M4's automation (D-33) ship as one YAML addition or two.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### This phase's own research — read first
- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-RESEARCH.md` — **the primary
  implementation guide.** Contains the exact export line with every option justified from
  `exports(5)`; the `infra/nfs-music-export.tf` `null_resource` + `triggers` shape; the seven-stage
  empirical decision protocol with literal commands; the Route A/Route B analysis and Route B's full
  fallback specification; the reboot-race mechanism traced through Supervisor source; the
  `albumartist` requirement confirmed in MA source; the nine common pitfalls; and the
  `check-music-consumers.sh` skeleton. **Read its § "Session Limitation" first** — no live estate
  access was available, so every claim about *current* state is `[ASSUMED]` and Stage 0 must measure
  it. Decisions D-01 … D-56 above resolve its A8/A11 flags and Open Questions 1–5.

### Project planning
- `.planning/ROADMAP.md` § "Phase 2: NFS Export and Music Assistant Reachability" — the five success
  criteria, and why this phase runs in parallel with Phase 1 and must complete before Phase 7
- `.planning/REQUIREMENTS.md` § "Consumers — two, not one" — CONS-01, CONS-02, CONS-03 (and CONS-04,
  which this phase builds tooling for but does not deliver)
- `.planning/phases/01-safety-harness-and-freeze-the-writers/01-CONTEXT.md` — D-11 (`568:568`
  ownership, which becomes `anonuid`/`anongid`), D-12 (mode target, **scoped out — see below**),
  D-20 (nobody holds `rw` on Music until Phase 6), D-29 (health-check folding precedent), D-30
  (document-beside-the-stack precedent)
- `.planning/STATE.md` § Key Learnings — the `aclmode=restricted` / `chmod EPERM` finding that
  scoped out Phase 1's D-12 mode normalisation, the `.DS_Store` uncounted-writer finding (01-06),
  and the Jellyfin `ApiKeys` finding relevant to D-40
- `.planning/phases/03-tagger-spike/03-CONTEXT.md` § D-04 — the secrets-storage pattern D-39 mirrors

### Estate conventions and constraints
- `CLAUDE.md` § "Infrastructure Rules" — Terraform authoritative for host resources; provisioning
  logic in `infra/` only (a hand-run `exportfs` is a defect — governs D-15)
- `CLAUDE.md` § "Music Assistant on HAOS: mounting the library" — the Option A / Option B export
  models; **PROJECT.md's current assertion that HA storage configuration is the route must be
  corrected by criterion 5 either way** (D-47)
- `CLAUDE.md` § Constraints — `acltype=nfsv4` + `aclmode=restricted`, the `0777` reality, and that
  knfsd does not export NFSv4 ACLs so mode bits are the only lever NFS clients see
- `CLAUDE.md` § "What NOT to Use" — `no_root_squash` forbidden (D-51); never stage untagged content
  under `/media/Music` (governs D-04)
- `NETWORK.md` — host/IP map; atlantis `172.16.1.158`, the NUC `172.16.1.31`. **Extended by D-48.**
- `STANDARDS.md` § "Volume Mounting" line 141 — `568:568` (`apps:apps`) as the estate service account

### Files this phase creates or modifies
- `infra/nfs-music-export.tf` — **new.** The export, the guarded `nfs-kernel-server` install, M1/M2,
  and the D-15 flagged temporary export
- `infra/host.tf` — the existing `remote-exec`-over-SSH host-config pattern the new file follows
- `scripts/check-music-consumers.sh` — **new.** Both-consumer assertions (D-41, D-42)
- `scripts/check-music-freeze.sh` — the read-only-by-contract and exit-code convention to match
- `scripts/quick-health-check.sh` — the audit script folds in here (D-41)
- `stacks/selfhosted/arrs/beets.md` — extended with the operational record (D-47)
- `.planning/PROJECT.md` — Key Decisions for criterion 5 (D-47)

### Host-side and off-repo
- `~/.claude/skills/ha-deercrest/SKILL.md` — **the mechanism for driving HAOS non-interactively**:
  the SSH invocation and the `bash -lc` wrapper without which the `ha` CLI returns `unauthorized`
  (D-22)
- `/mnt/fast/secrets/` on LXC 100 — the MA token and the Jellyfin API key (D-39, D-40).
  **Never committed.**
- `/config/secrets.yaml` on the NUC — M4's separate MA token as `!secret` (D-34). **Never committed.**

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`infra/host.tf`** — establishes `null_resource` + `remote-exec` over SSH as this repo's
  host-config mechanism. `infra/` uses `bpg/proxmox ~> 0.95` plus `hashicorp/null ~> 3.2`. There is
  no config-management tier, so this is the honest way to express an `/etc/exports.d` drop-in.
- **`scripts/check-music-freeze.sh`** — Phase 1's read-only audit script. Supplies the exit-code
  convention D-41 inherits: every red finding increments `FAILURES` and exits non-zero; `--baseline`
  prints everything and always exits 0.
- **`scripts/quick-health-check.sh`** — the standing estate check the new script folds into (D-41),
  and the before/after blast-radius snapshot (D-44).
- **`scripts/snapshot-music-tags.sh` / `scripts/diff-music-tags.sh`** — Phase 1's QUAL-01 tooling.
  Its NDJSON snapshot is the source for D-07's album selection and D-09's pinned expectations.
- **`scripts/setup-*.sh`** — the idempotent-setup-script convention, if any host work lands outside
  Terraform.

### Established Patterns
- **A `.md` beside the stack it documents** (`arrs/beets.md`, `media/dispatcharr.md`) — D-47 extends
  `beets.md` rather than creating a new file, because MA has no stack in this repo.
- **Terraform is authoritative for host/LXC/VM resources only**; application settings inside
  containers have no provider. MA and Jellyfin config is therefore script- and API-driven, not
  Terraform — the same reasoning that produced Phase 1's D-27.
- **Vendoring config that must survive rebuilds** (SABnzbd `scripts_init.bash`, and Phase 1's D-28
  beets config) — relevant to D-29's provider-config capture.
- **Version pinning over floating tags** — the repo prohibits `:latest`/`:nightly` on tools that
  write to the library. D-56 notes the operator chose auto-update for the MA add-on anyway, which
  shifts the burden onto the audit script.

### Integration Points
- **Inherits Phase 1 D-11** — `568:568` becomes `anonuid`/`anongid` (D-12). ROADMAP C-9 makes this
  binding, which is what forces CLAUDE.md's Option B over Option A.
- **Inherits Phase 1's `aclmode=restricted` finding** — the tree is `0777` and cannot be changed, so
  there is no mode-based way to make a writable export safe. The export *must* be `ro`; this is a
  constraint, not a preference.
- **Inherits Phase 1 D-20** — nobody holds `rw` on Music until Phase 6, which is why D-05's failure
  branch cannot include tag repair.
- **Feeds Phase 7 CONS-04** — `check-music-consumers.sh` (D-41/D-42) is the tool CONS-04's
  "visible in both Jellyfin and Music Assistant" gate calls, with the D-09 pinned album set.
- **Feeds Phase 7 QUAL-03** — D-06's three shapes anticipate "include the historically painful
  cases" one phase early.
- **Touches nothing Phase 3 depends on** — the spike works in `tank/downloads` against throwaway
  containers; this phase adds a reader on `tank/media/Music`.

</code_context>

<specifics>
## Specific Ideas

- **The strongest single option is `mountpoint`, and it is in neither of CLAUDE.md's candidates.**
  It refuses to export a path unless that path is itself a mount point — so a host reboot where
  `nfs-server` starts before `zfs-mount` exports *nothing* rather than the empty stub directory
  underneath the unmounted dataset. Free, and it closes the only failure mode that can silently
  corrupt MA's state from the server side.
- **Two premises carried in from the ROADMAP are wrong and the plan must not repeat them.**
  (1) *"Music Assistant never purges stale entries"* is **false** — `sync_library()` computes
  `prev_filenames - cur_filenames` and calls `_process_deletions()` every sync. It is guarded (a
  scan returning zero files against a previously non-empty library aborts deletions) but not absent.
  The three-album gate is still right, for the better reason that album identity is
  `albumartist + os.sep + album`, so a wrong album artist creates a durable wrong-artist entry.
  (2) The reboot race is **not** a Supervisor ordering bug — `sys_mounts.load()` runs before
  `sys_apps.load()`. The real failure is that an unreachable server inside the ≤40 s window makes
  Supervisor bind-mount an **empty read-only emergency directory** at `/media/<name>`, so MA sees a
  path that exists and is empty.
- **"Files are visible" is explicitly not the gate**, and neither is "an album appeared". D-10's
  exact match and D-11's read-through hash exist because both weaker forms pass on a stale library.
- **A wrong album artist and a broken mount must be distinguishable.** That is the entire reason
  D-07 pre-verifies the three albums from the snapshot before they are used as the gate.
- **The `.DS_Store` owned `65534:65534` in the library root means a macOS client already has write
  access to this tree over some share nobody has named.** This phase is already enumerating what
  serves the tree, so extending that probe to SMB/Samba costs almost nothing and turns an inferred
  writer into a named one (D-32 / deferred below).
- **`fsid=0` must not be added.** Both consumers mount the full path — HA Supervisor builds
  `f"{server}:{path}"` and so does MA — and `fsid=0` would relocate the pseudo-root and require the
  client path to become `/`, breaking both. Old tutorials recommend it; `exports(5)` and the
  nfs-utils maintainers' wiki no longer do.

</specifics>

<deferred>
## Deferred Ideas

- **Closing the macOS/SMB writer on the library tree.** D-32 identifies and *names* it as part of
  Stage 0's share enumeration, but closing it is a WRIT-class change in a consumer-reachability
  phase, and it may be a share the house actively uses. Deferred with an identified target rather
  than left as an open mystery. Related: `/mnt/tank/media/TV`'s 114,218 entries on orphan gid 545,
  already recorded as OPEN/UNOWNED in STATE.md.
- **Exporting other media trees, or to additional clients.** D-16 keeps scope at Music/one client.
  A generalised Terraform export module was considered and rejected as speculative structure; the
  D-15 enable flag already shows the pattern extends.
- **Kerberos (`sec=krb5`) for the export.** Considered and rejected (D-50) — a KDC for one
  read-only LAN music share, with unproven HAOS-side support.
- **RPC-with-TLS (`xprtsec=`, RFC 9289).** Considered and rejected (D-49), recorded explicitly so
  the security review has an answer rather than a silence.
- **Shortening MA's `sync_interval`.** Rejected as M5 (D-38) — blunt, and increases scan load on a
  34 GB tree for a rare event. Revisit only if Phase 7/9 bulk imports make staleness painful.
- **Pinning the MA add-on version / disabling auto-update.** Explicitly declined by the operator
  (D-56). Revisit if an MA release ever breaks the pipeline — the audit script is the detector.
- **Broader active alerting for the estate.** D-54 adds one HA notification on `MOUNT_FAILED`.
  A general "things are silently down" alerting story — given the dispatcharr/teleport six weeks and
  podsync's thirteen months — is a separate capability and its own decision.
- **Making Jellyfin's Music mount genuinely `:ro`.** Carried forward from Phase 1's deferred list;
  Jellyfin remains the documented consumer-class exception. Worth revisiting once the tagger owns
  the tree.

</deferred>

---

*Phase: 2-nfs-export-and-music-assistant-reachability*
*Context gathered: 2026-08-28*
