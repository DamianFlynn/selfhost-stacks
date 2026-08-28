# Phase 2: NFS Export and Music Assistant Reachability - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-28
**Phase:** 02-nfs-export-and-music-assistant-reachability
**Areas discussed:** Album-artist fallback, The three albums, Reboot-proof depth, Evidence & token,
Temp export lifecycle, Terraform drift, Stage 0 preconditions, Blast radius, MA sync interval,
Export scope, Route B fallback trigger, MA add-on version, Security posture, HAOS access mechanism,
Playback proof, The other share, Plan shape & checkpoints, End-of-phase verification,
HA media exposure, Mount hygiene, MA provider config, NETWORK.md, Failure alerting

**Note:** `02-RESEARCH.md` already existed before this discussion (written without live estate
access). Many questions below were framed against its findings — confirming its recommendations, or
deciding the items it explicitly flagged as needing user confirmation (A8, A11, Open Questions 1–5).

---

## Album-artist fallback

| Option | Description | Selected |
|--------|-------------|----------|
| `folder_name` | Falls back to the containing folder name; agrees with a correct tag and disagrees loudly when absent | ✓ |
| `various_artists` (MA default) | Indistinguishable from the many legitimate VA compilations in this library | |
| `track_artist` | Shatters a compilation into one entry per track | |

**User's choice:** `folder_name`
**Notes:** Resolves research A11, which was flagged `[ASSUMED — reasoned, needs user confirmation]`.

| Option | Description | Selected |
|--------|-------------|----------|
| Prove it fires | Add a control album with no albumartist and observe the fallback | ✓ |
| Happy path only | The three albums are correct by definition; fallback never fires | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| 2nd temp export + provider | Scratch dir under `tank/downloads`, torn down at phase end | ✓ |
| Temporarily inside the library | Violates CLAUDE.md's staging constraint | |
| Config + log only | Proves the setting is stored, not that it works | |

| Option | Description | Selected |
|--------|-------------|----------|
| Permanent | Recorded in PROJECT.md as a Key Decision | ✓ |
| Pilot-only, revisit at Phase 7 | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Stop, diagnose, don't fix tags | No `rw` on Music until Phase 6; swap the album or fix MA config | ✓ |
| Record and continue | Weakens the three-album gate | |
| You decide | | |

---

## The three albums

| Option | Description | Selected |
|--------|-------------|----------|
| Three shapes | single-artist + multi-disc + legitimate Various Artists | ✓ |
| Three easy single-artist albums | Fastest clean proof | |
| Three shapes + the DJ shape | Tests Phase 6/7's problem in Phase 2 | |

| Option | Description | Selected |
|--------|-------------|----------|
| From the QUAL-01 snapshot, verified | Correctness pre-verified so an MA failure is unambiguous | ✓ |
| Operator picks by eye | "Known to be right" is an assertion, not evidence | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Pinned in the audit script, reused | Same three for the reboot, the negative control, Phase 7 CONS-04 | ✓ |
| Pinned in CONTEXT/PLAN docs only | | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Substitute from the backlog via the temp export | Shape gets exercised rather than skipped | ✓ |
| Record the gap and test the shapes that exist | | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Exact match vs the snapshot | Album name and `artists[].name` byte-for-byte | ✓ |
| Exact match + track count | | |
| Album present under a non-empty artist | Cannot distinguish a fallback entry from a correct one | |

---

## Reboot-proof depth

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, both controls | Positive reboot + deliberate outage including the ~900s unattended-recovery wait | ✓ |
| Positive reboot only | Criterion 4 passes by luck | |
| Negative control, but no 900s wait | Doesn't prove unattended recovery | |

| Option | Description | Selected |
|--------|-------------|----------|
| M1 `mountpoint` on the export | Server-side half removed entirely | ✓ |
| M2 `After=zfs-mount.service` drop-in | Belt and braces | ✓ |
| M3 Supervisor's 900s reload | Upstream's designed self-heal | ✓ |
| M4 boot-time auto-sync automation | Collapses staleness ≤12h → ~2 min | ✓ |

**User's choice:** all four (multi-select)

| Option | Description | Selected |
|--------|-------------|----------|
| Gate M4 on a working rest_command, token stays on the NUC | Drops to a deferred idea if it doesn't work | ✓ |
| Build M4 unconditionally | | |
| Reuse the same token as the audit script | One leak costs both | |

| Option | Description | Selected |
|--------|-------------|----------|
| Flag as a human checkpoint | `autonomous: false`, matching Phase 1's convention | ✓ |
| No constraint — run it inline | | |
| Human checkpoint + verify tailnet path first | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Test it without rebooting atlantis | Simulated unmount; assert `exportfs -v` exports nothing | ✓ |
| Real atlantis reboot | Takes the whole estate down; amdgpu history | |
| Neither — argue it from exports(5) | Leaves M2 unverified | |

| Option | Description | Selected |
|--------|-------------|----------|
| Captured transcripts under the phase dir | All three proof lines, or the control didn't fire | ✓ |
| Summarised in the phase SUMMARY only | | |
| You decide | | |

---

## Evidence & token

| Option | Description | Selected |
|--------|-------------|----------|
| `/mnt/fast/secrets/` on LXC 100 | Mirrors Phase 3 D-04's Discogs pattern | ✓ |
| `~/.claude/secrets/` on the workstation | Secret sits away from the box running the script | |
| Both — estate copy + workstation copy | Two places to rotate, two to leak | |

| Option | Description | Selected |
|--------|-------------|----------|
| Ships now + folds into `quick-health-check.sh` | Phase 1 D-29 precedent | ✓ |
| Ships now, standalone | | |
| Assertions inline, no script | Nothing for Phase 7 to call | |

| Option | Description | Selected |
|--------|-------------|----------|
| Complete `/setup` as a checkpointed step | One-off config gap, not new scope | ✓ |
| Block and escalate | Would stall Phase 7 CONS-04 too | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Discover first, GUI fallback for creation only | `/api-docs/commands.json` is unauthenticated | ✓ |
| GUI creation, don't attempt discovery | | |
| Headless or fail | Stakes the phase on an undocumented runtime detail | |

| Option | Description | Selected |
|--------|-------------|----------|
| Key Decision + a route note in `beets.md` | PROJECT.md for direction, `beets.md` for runbook | ✓ |
| PROJECT.md only | | |
| A new `music-assistant.md` beside the stack | MA has no stack in this repo | |

| Option | Description | Selected |
|--------|-------------|----------|
| 365-day token, rotate at project close | Same moment as the Discogs token | ✓ |
| Short-lived, re-minted per run | Moves the admin password into the script's reach | |
| 365-day, no rotation plan | | |

---

## Temp export lifecycle

| Option | Description | Selected |
|--------|-------------|----------|
| Terraform, with an explicit enable flag | Teardown is `terraform apply` with the flag off | ✓ |
| Hand-run, documented | Drifts the host from `infra/` — CLAUDE.md C-1 forbids it | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Assert both sides are gone | Export absent AND MA provider/items absent | ✓ |
| Assert the export only | Leaves stale MA entries possible | |
| You decide | | |

---

## Terraform drift

> **Raised by the operator mid-discussion:** *"we just need to check terraform in case of drift also"*

| Option | Description | Selected |
|--------|-------------|----------|
| Clean plan required before touching `infra/` | Otherwise pre-existing drift is swept into this apply | ✓ |
| Record drift, proceed with targeted apply | Leaves criterion 1 true only for the targeted subset | |
| Record drift, fix it, then proceed | Pulls unknown-size estate work into this phase | |

| Option | Description | Selected |
|--------|-------------|----------|
| Blocking checkpoint, operator decides | Reverting drift on a 78-container host isn't autonomous | ✓ |
| Auto-switch to targeted apply | Normalises working around drift | |
| You decide | | |

---

## Stage 0 preconditions

| Option | Description | Selected |
|--------|-------------|----------|
| Probe, and block on any hit | Two export tables for one path is silent misbehaviour | ✓ |
| Probe, record, converge with `exportfs -ra` | | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Measure it from the NUC, don't assume | The NUC is also a subnet router — source address can surprise | ✓ |
| Trust NETWORK.md, diagnose on failure | Failure lands after the export is deployed | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Guarded install via Terraform, service enabled | Re-apply is a no-op — what criterion 1 measures | ✓ |
| Install as a separate, explicitly-checkpointed step | | |
| You decide | | |

---

## Blast radius

| Option | Description | Selected |
|--------|-------------|----------|
| Assert Jellyfin + estate health before and after | CLAUDE.md C-6: argued, not assumed | ✓ |
| Jellyfin check only | Narrow checks have missed things for weeks here | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Documented teardown, both sides | Nothing writes content; the risk is a half-built mount graph | ✓ |
| Leave it in place, resume later | Leaves an unexplained export in the estate | |
| You decide | | |

---

## Route B fallback trigger

| Option | Description | Selected |
|--------|-------------|----------|
| A fails at the mount or the `ro` proof | The only two things Route B changes | ✓ |
| Any Route A failure at all | Risks abandoning the maintainer-confirmed route | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Re-characterise the race for B, keep both controls | B has no emergency bind, so the proof lines differ | ✓ |
| Keep the same tests, accept the gap | Criterion 4 would rest on a test built for another architecture | |
| You decide | | |

---

## MA add-on version

| Option | Description | Selected |
|--------|-------------|----------|
| Measure first, then pin stable | Record the exact version every criterion was proven at | ✓ |
| Whatever is installed, just record it | | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Turn off auto-update, record the version | | |
| Leave auto-update on, rely on the audit script | Detection is reactive; makes the script load-bearing | ✓ |
| You decide | | |

**Notes:** The operator chose currency over pinning, against the recommendation. Recorded in
CONTEXT.md as D-56 with the consequence made explicit: `check-music-consumers.sh` becomes the only
mechanism that would catch an MA release changing provider behaviour under the pipeline.

---

## Security posture

| Option | Description | Selected |
|--------|-------------|----------|
| Accept, record explicitly | `xprtsec=` considered and rejected; gives the security gate an answer | ✓ |
| Harden with Kerberos/krb5 | A KDC for one read-only music share | |
| You decide | | |

---

## HAOS access mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Re-verify at Stage 0, leave as-is | Protection mode stays off; the standing check depends on it | ✓ |
| Re-verify, and close protection mode after | Would break the folded health check | |
| You decide | | |

---

## Playback proof

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — read bytes through the mount | An MA entry can be a survivor from before the mount broke | ✓ |
| Yes — stream a track through MA | Adds player/codec failure surface | |
| No — library entry is enough | "Visible" and "readable" come apart in the guarded failure mode | |

| Option | Description | Selected |
|--------|-------------|----------|
| Plain file hash, both sides | Sidesteps busybox tooling assumptions entirely | ✓ |
| `ffprobe` inside the MA container | Depends on exec-into-add-on, a HAOS unknown | |
| You decide | | |

---

## The other share

| Option | Description | Selected |
|--------|-------------|----------|
| Identify it, don't close it | Named writer instead of an inferred one; closing is WRIT-class | ✓ |
| Identify and close it | A writer-freeze change in a consumer-reachability phase | |
| Out of scope entirely | Leaves an unnamed writer while adding a second reader | |

---

## Plan shape & checkpoints

| Option | Description | Selected |
|--------|-------------|----------|
| Server-side, then NUC-side | Plan 1 satisfies CONS-01 alone and is independently shippable | ✓ |
| One plan, sequential | | |
| You decide | | |

---

## End-of-phase verification

| Option | Description | Selected |
|--------|-------------|----------|
| Script verdict + open MA yourself | Criterion 3 is about what a person sees | ✓ |
| Script verdict alone | Proves the API answers correctly, not that MA is usable | |
| You decide | | |

---

## HA media exposure

| Option | Description | Selected |
|--------|-------------|----------|
| Accept, record as a known consequence | `usage: media` is what makes Route A work | ✓ |
| Constrain via HA permissions | HA's permission model is coarse | |
| Reconsider Route B on this basis | Large cost for a possibly-desirable consequence | |

---

## Mount hygiene

| Option | Description | Selected |
|--------|-------------|----------|
| Name `music`, assert target absent/empty first | A non-empty target degrades the mount silently | ✓ |
| Name `music`, mount and inspect after | Diagnosis is one layer removed from the cause | |
| You decide | | |

---

## MA provider config

| Option | Description | Selected |
|--------|-------------|----------|
| Filter by provider instance id, enumerate the rest | Display names are user-editable | ✓ |
| Filter by provider name | Would break the standing check silently on a rename | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Read the whole config back and record it | MA's defaults already proved a trap once in this phase | ✓ |
| Assert the two critical keys only | | |
| You decide | | |

---

## NETWORK.md

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — export line, both endpoints, the port | A new listening service between two mapped hosts | ✓ |
| No — PROJECT.md and `beets.md` are enough | | |

---

## Failure alerting

| Option | Description | Selected |
|--------|-------------|----------|
| Health-check exit code only, note the gap | | |
| Add an HA notification | On Supervisor's `MOUNT_FAILED` repairs issue | ✓ |
| You decide | | |

**Notes:** Chosen against the recommendation to defer. Rationale accepted: the estate's
silent-outage history (dispatcharr/teleport six weeks; podsync thirteen months) means an exit code
nobody reads is not detection. Pairs naturally with M4's automation.

---

## Claude's Discretion

Explicitly left to Claude (no "You decide" was selected during discussion; these were stated in
CONTEXT.md as discretion areas rather than chosen):

- Scratch-directory naming under `tank/downloads`, Terraform variable/resource naming, `exports.d`
  filename
- `check-music-consumers.sh` internals and output formatting, subject to the read-only contract and
  `check-music-freeze.sh`'s exit-code convention
- Task ordering within each plan; whether Stage 0's probes are one task or several
- The checksum algorithm for the read-through proof
- Whether the HA notification and M4's automation ship as one YAML addition or two

## Deferred Ideas

- Closing the macOS/SMB writer on the library tree (identified here, not closed)
- Exporting other media trees or to additional clients; a generalised Terraform export module
- Kerberos (`sec=krb5`) — considered and rejected
- RPC-with-TLS (`xprtsec=`, RFC 9289) — considered and rejected
- Shortening MA's `sync_interval` (M5) — rejected
- Pinning the MA add-on / disabling auto-update — explicitly declined by the operator
- Broader active alerting for the estate beyond the single `MOUNT_FAILED` notification
- Making Jellyfin's Music mount genuinely `:ro` (carried forward from Phase 1)
