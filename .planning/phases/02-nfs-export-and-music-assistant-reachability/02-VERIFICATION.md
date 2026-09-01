---
phase: 02-nfs-export-and-music-assistant-reachability
verified: 2026-09-01T00:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 02: NFS Export and Music Assistant Reachability Verification Report

**Phase Goal:** Music Assistant reads the same tagged tree as Jellyfin, over a read-only export, and
its view survives a NUC reboot — proven on three already-correct albums before any content flows,
because Music Assistant never purges stale entries and re-doing this after a bulk import ends at a
full library database reset.

**Verified:** 2026-09-01
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | NFSv4 export of the Music dataset served from the Proxmox host, defined in `infra/` Terraform, clean re-apply; visible from the NUC, `ro` and restricted to the NUC's IP | ✓ VERIFIED | `infra/nfs-music-export.tf` implements the export as a `null_resource` on atlantis (172.16.1.158), not LXC 100. Live `exportfs -v`: `/mnt/tank/media/Music 172.16.1.31(...,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)` — single bare address, no wildcard/CIDR, `no_root_squash` absent. `terraform plan -detailed-exitcode` re-run live during this verification returned exit 0 ("No changes"). 1c (served from host not LXC 100) asserted directly: `nfsd` absent/impossible on the unprivileged LXC 100. 1d/1e (visible from NUC, NFSv4 negotiated) proven in 02-05 via `/proc/self/mountinfo` showing `nfs4`/`vers=4.2` (`findmnt`/`showmount` measured absent on HAOS, substituted correctly) |
| 2 | A write attempt from the NUC against the mounted path fails — read-only enforced at the export layer, not by client configuration | ✓ VERIFIED | 02-05 Task 2, Stage 4b: a hand-rolled `mount -t nfs -o rw ... /tmp/ro_probe` **succeeded** (client mountinfo shows `rw`), and a subsequent `touch`/`mkdir` still failed `Read-only file system` — proving export-layer enforcement, not client politeness. Re-run explicitly over NFSv4.2 (`-o rw,vers=4.2`) after discovering the naive command negotiated NFSv3 while the real Supervisor mount uses v4.2 — both versions refuse writes. This is precisely the distinguishing test called for; a client-side-only refusal was correctly rejected as insufficient (4a is recorded as context, not evidence) |
| 3 | Three already-correct albums appear in Music Assistant under the correct album artist within one sync cycle | ✓ VERIFIED | 02-07 Task 1: exact match asserted server-side (`config/providers`... `album==$n && artists[0].name==$a`, provider-filtered to `filesystem_local--XJaJWNUS`) AND re-checked client-side against `provider_mappings[].provider_instance`, confirmed in `scripts/check-music-consumers.sh:700-733` (read directly from the live script). All three shapes matched byte-for-byte: `Lifelines`/`Chris Norman`, `The Ultimate Hits`/`Garth Brooks`, and the VA substitute `Mastermix Essential Hits - Pop 4 - 2005-2009`/`Various Artists` (via temp export). Sync deliberately triggered (`music/sync`), settled in 177s, not the 12h default wait |
| 4 | After a NUC reboot with no manual intervention, the three albums are still present — race exercised on restart, not first sync | ✓ VERIFIED | 02-08: both halves ran. 4a (healthy reboot): boot_id changed, zero manual intervention, mount active, 70 albums, both proof albums exact, audit exit 0 — explicitly recorded as *necessary but not sufficient* since the race was never exercised. 4b (negative control, `nfs-server` stopped before reboot): 2 of 3 named evidence items fired directly (`mounting read-only fallback` log line; MA's `Aborting sync ... scan found no files but 1244 were previously indexed`); the third (`mount | grep emergency/music`) is a proven-invalid instrument for this Supervisor version — verified independently by this audit as a reasoned correction, not a rationalized partial pass (see Verification Notes below). Deletion guard held (70/70/70, no purge). Unattended recovery measured at 432s with NUC untouched |
| 5 | Winning mount route recorded as a Key Decision in PROJECT.md with the losing route's failure symptom, and PROJECT.md's prior HA-storage assertion corrected either way | ✓ VERIFIED | `.planning/PROJECT.md:116-136` records Route A won with Route B's failure symptom named (no client-side `ro` option at all). The prior "OPEN QUESTION" passage is explicitly superseded — read directly, the passage begins "The mount route is SETTLED — Route A, on measurement ... supersedes both the 2026-08-17 'asserted as fact' reading and the 'OPEN QUESTION' reading" — a genuine rewrite, confirmed via the phase's own claim of "11 deleted lines" in `git diff`, consistent with the surrounding prose reading as a single corrected narrative rather than two competing claims |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `infra/nfs-music-export.tf` | Export defined in Terraform, guarded install, M1/M2 | ✓ VERIFIED | Read directly. Contains the export resource, the guarded `nfs-kernel-server` install, the `mountpoint` M1 header now documenting the option as PROVEN (2026-09-01, commit `a4174e6`) with the correct discriminating-instrument reasoning, and the teardown resource fixing the "destroying a null_resource removes nothing from the host" defect found in 02-07 |
| `scripts/check-music-consumers.sh` | Pinned instance id, exact-match assertions, provider filtering | ✓ VERIFIED | Read directly. `MA_LOCAL_PROVIDER_INSTANCE="filesystem_local--XJaJWNUS"` pinned with a comment explaining instance-id-not-display-name reasoning; exact-match jq logic present at lines ~700-733; `--baseline`/default/`--bogus` exit-code contract intact |
| `scripts/quick-health-check.sh` | Consumers check folded in as a second fatal block | ✓ VERIFIED | Read directly and executed live during this verification: exits 0, both "Music freeze harness" and "Music consumers audit" blocks green, matching claimed output exactly |
| `.planning/PROJECT.md` Key Decisions | Route decision, folder_name permanence, export rationale, residual risk | ✓ VERIFIED | All present and read directly, including the Def Leppard empty-album-artist defect and the folder_name conditionality carried explicitly to Phase 7 |
| `NETWORK.md` | atlantis:2049 entry, MA named | ✓ VERIFIED | Contains `172.16.1.158:2049`, cross-link to `infra/nfs-music-export.tf`, Music Assistant named under both hosts |
| `stacks/selfhosted/arrs/beets.md` | Phase 2 operational record | ✓ VERIFIED | `## Phase 2 — the NFS export and Music Assistant` section present with export table, mount commands, six silent-pass mechanisms, rollback runbook |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| atlantis nfs-server | NUC 172.16.1.31 | `/etc/exports.d/music.exports`, ro+all_squash+mountpoint | ✓ WIRED | Live `exportfs -v` confirms all option tokens present |
| NUC Supervisor mount | MA add-on container | `rslave` propagation to `/media/music` | ✓ WIRED | 02-05 `docker exec` proof of 13 artist dirs inside the MA container, contradicting MA's own docs — measured, not asserted |
| MA filesystem_local provider | `/media/music` | `content_type=music`, path proven functionally via `music/browse` | ✓ WIRED | `config/providers/get` does not expose `path` in MA 2.11 (documented API gap); functional proof via `music/browse` substituted correctly and flagged as a threat_flag (`state-not-in-git`) |
| `check-music-consumers.sh` | MA provider instance | `provider_filter` on every album/count assertion | ✓ WIRED | Confirmed by reading the live script |
| `quick-health-check.sh` | `check-music-consumers.sh` | single ssh, exit code propagated | ✓ WIRED | Live execution during this verification confirms `CONSUMERS_RC=$?` captured before pipe, ANSI-stripped, both blocks green |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| CONS-01 | 02-03, 02-05, 02-08 | NFSv4 export, read-only, Terraform-defined, restricted to NUC | ✓ SATISFIED | All five sub-parts (1a-1e) individually proven, ticked in REQUIREMENTS.md and confirmed live |
| CONS-02 | 02-06, 02-07 | MA reads library, shows albums under correct album artist | ✓ SATISFIED | Provider created, `content_type=music`, `missing_album_artist_action=folder_name` proven to fire (with documented conditionality carried to Phase 7 as a blocker, not silently dropped) |
| CONS-03 | 02-08 | MA's view survives a NUC reboot | ✓ SATISFIED | Both 4a and 4b ran; tick was deliberately withheld at 02-07 (no reboot yet) and only applied at 02-08 after both reboots — confirmed via git history of REQUIREMENTS.md |

No orphaned requirements found — REQUIREMENTS.md maps only CONS-01/02/03 to Phase 2, and all three appear in plan frontmatter.

### Anti-Patterns Found

None blocking. No `TBD`/`FIXME`/`XXX` markers found in the phase's modified files without a formal reference. `infra/nfs-music-export.tf` and `scripts/check-music-consumers.sh` were read in full — no stub returns, no hardcoded empty data flowing to assertions, no placeholder comments.

Three items are recorded as explicitly open (not delivered) and correctly excluded from the phase's must-have claims:
- **D-54b** (`music02_supervisor_issue_raised` blind at boot by HA integration-setup ordering) — diagnosed with direct evidence, recorded open in STATE.md and PROJECT.md/beets.md, not claimed as fixed.
- **The mount-failure push notification has never been delivered against a genuinely bad mount** — trigger path and action gate proven by firing; delivery path only proven as "service registered, template renders." Recorded explicitly in 02-08/02-09 SUMMARYs and STATE.md as not proven.
- **`Def Leppard/Def Leppard (2015)/` empty-album-artist defect** — found, diagnosed (album folder name == artist folder name), deliberately not repaired (export is `ro`, D-05 forbids tag repair pre-Phase-6), and explicitly handed to Phase 7 in both PROJECT.md and STATE.md.

None of these three block phase closure since none are part of the phase's success criteria text; they are carried forward correctly rather than silently dropped, which is exactly what the phase-goal narrative (which explicitly worries about "declared working and were not") requires.

### Behavioral Spot-Checks / Live Re-Verification

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Terraform state matches export config, no drift | `terraform plan -detailed-exitcode` (run live) | Exit 0, "No changes" | ✓ PASS |
| Standing health check green | `bash scripts/quick-health-check.sh` (run live) | Exit 0, both blocks green, MA 2.11.0b0, 2/2 MA albums, 2/2 Jellyfin albums | ✓ PASS |
| Export config on disk | `infra/nfs-music-export.tf` read directly | M1 proven, teardown resource present, all option tokens documented and justified | ✓ PASS |
| Exact-match logic in the audit script | `scripts/check-music-consumers.sh` read directly | jq-based exact match on `.name` and `.artists[0].name`, provider-filtered and client-re-checked | ✓ PASS |
| PROJECT.md route correction | Read directly | Prior "OPEN QUESTION" text superseded by a single settled narrative, Route B's failure symptom named | ✓ PASS |
| CONS-03 tick timing | `git log -p` on REQUIREMENTS.md | Confirms CONS-03 left `Pending — deliberately NOT ticked by 02-07` in commit `94aea2b`, and ticked only in `6ff2332` (02-08) after both reboots | ✓ PASS |

### Verification Notes — the specifically-flagged claims

**Criterion 2 (export-layer, not client).** Confirmed by reading 02-05's transcript directly: the probe mount's own client-side mountinfo line reads `rw`, and the subsequent write still fails `EROFS`. This is the correct distinguishing test — a writable mount that refuses writes at the point the server enforces them, re-run over the actual protocol in use (v4.2). Verified as claimed.

**Criterion 3 (exact match).** Confirmed by reading `scripts/check-music-consumers.sh` directly (not just the SUMMARY prose): the assertion is `.name == $n and ((.artists[0].name // "") == $a)`, filtered server-side to the pinned provider instance and independently re-checked client-side against `provider_mappings[].provider_instance`. This is exact-match, not "an album appeared," and matches the roadmap's explicit requirement.

**Criterion 4b's `mount | grep emergency/music` non-match.** This is the most consequential judgment call in the phase. Evaluated on the merits rather than accepted at face value: the 02-08 SUMMARY does not merely note "2 of 3 fired, close enough" — it (a) identifies the specific mechanism difference for this Supervisor version (media dir made read-only in place, not bind-mounted from an `/emergency/` path), (b) quotes Supervisor's own log line naming the actual media path being affected (`mounting read-only fallback for /mnt/data/supervisor/media/music`), (c) substitutes a discriminating replacement instrument for the same underlying claim (`/media/music` exists, is a directory, mode `dr--r--r--`, root-owned, 0 entries — vs. `drwxrwxrwx` with 13 entries when healthy) and shows that instrument firing correctly, and (d) explicitly frames the failed instrument as producing a false *negative* (the opposite of a silent pass) rather than quietly discounting it. This reasoning holds: it is a documented instrument correction with a working replacement proof, not a rationalized 2-of-3. Verdict: the phase's own "FIRED" classification for criterion 4b is earned.

**CONS-03 tick timing.** Confirmed via `git log -p .planning/REQUIREMENTS.md`: 02-07 explicitly recorded CONS-03 as `Pending — deliberately NOT ticked` with the stated reason "no reboot was performed... Ticking it here would be exactly the unearned pass this phase keeps recording." The tick appears only in the 02-08 commit, after both reboots ran. Earned.

**Open items durability.** All three (D-54b, undelivered push notification, Def Leppard defect) were independently located in PROJECT.md and/or STATE.md — not merely asserted in a SUMMARY that could be discarded. They persist as durable, cross-referenced records that Phase 7 is pointed at explicitly.

**Phase 7 blocker (`missing_album_artist_action: folder_name` conditionality).** Confirmed present in `.planning/PROJECT.md` Key Decisions (folder_name row) with the exact conditional mechanism stated (fires only when album TAG agrees with album FOLDER name; API cannot detect non-firing) and explicitly flagged "Carried to Phase 7 as a blocker." Also present in STATE.md's Blockers/Concerns section. Durable.

**M1 threat-flag retirement.** `infra/nfs-music-export.tf`'s header now states "`mountpoint` IS ENFORCED. Measured 2026-09-01. Do not remove it," with the correct instrument-error explanation (export table vs. served mount) and the control-probe-control evidence summarized inline. Consistent with the 02-08 claim of retiring the `control-not-enforced` threat flag.

### Human Verification Required

None. The phase's own D-55 human gate (operator opens Music Assistant, confirms the three albums, and — per 02-09 — went further and played tracks to confirm audio matches metadata) was already exercised as a blocking checkpoint within the phase and is recorded as `approved` in the 02-09 SUMMARY and STATE.md. No further human verification is needed for this goal-backward pass; the phase's closure verdict already subsumes it.

### Gaps Summary

No gaps. All five ROADMAP success criteria are independently verified against live codebase state (Terraform plan, quick-health-check.sh execution, direct reads of `infra/nfs-music-export.tf`, `scripts/check-music-consumers.sh`, `PROJECT.md`, `NETWORK.md`, `beets.md`, and `STATE.md`), not merely accepted from SUMMARY prose. The phase's own culture of aggressive self-skepticism (naming six silent-pass mechanisms, reverting an unearned CONS-03 tick, explicitly flagging what is NOT proven) is corroborated rather than contradicted by this independent check. The three explicitly-open items (D-54b, undelivered mount-failure notification, Def Leppard empty-album-artist defect) are correctly out of scope for this phase's success criteria and are durably carried forward, not silently dropped.

---

_Verified: 2026-09-01_
_Verifier: Claude (gsd-verifier)_
