---
phase: quick-260918-byj
quick_id: 260918-byj
type: execute
plan: 01
wave: 1
depends_on: []
autonomous: true
files_modified:
  - .planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md
  - .planning/ROADMAP.md
  - .planning/STATE.md
  - stacks/selfhosted/arrs/beets.md
  - .planning/phases/04-collapse-to-one-tagger/04-18-PARTIAL.md
  - .planning/phases/04-collapse-to-one-tagger/04-19-PARTIAL.md
requirements: [QK-260918-byj]
user_setup: []

must_haves:
  truths:
    - "04-VERIFICATION.md's FRONTMATTER override is signed with the operator's own instructed values — accepted_by 'Damian Flynn', accepted_at '2026-09-18T07:36:35Z' (true UTC) — with status passed and overrides_applied 1, and the signature is proven by a YAML parse of the frontmatter region, never by a whole-file grep (the § Gaps Summary prose draft at line 250 already matches ^overrides:, accepted_by: and accepted_at: at column 1)"
    - "The document body — every byte after the SECOND `---` — is unchanged, proven by a sha256 equal to the recorded pre-edit baseline 5a1c5fb11577693189ce59a8b28ca1e25cf491e4b16ba4e2d78aef17161c2b16"
    - "The override's own reason: prose no longer instructs the reader that status stays gaps_found until the operator signs — that sentence became false at the signature, and a comment stating the opposite of the record beside it is the defect class this phase already fixed twice"
    - "ROADMAP line 52 is ticked with a note that says the phase closed at 5/5 with criterion 3 discharged by a SIGNED OVERRIDE rather than by byte proof, dated 2026-09-18, pointing at 04-VERIFICATION.md — and claims no byte proof anywhere"
    - "STATE.md reads completed_phases 5 / percent 50 with total_plans 63 and completed_plans 61 UNCHANGED (04-18 and 04-19 were never executed), Current Position moved to Phase 5 NOT_STARTED, edited by hand and with STATE.md's stale tail proven byte-identical"
    - "beets.md no longer carries an 'interim status' heading and no longer leaves criterion 3's disposition at window 2: the existing 2026-09-14 record is preserved verbatim and superseded by dated blockquotes in the file's own layering convention, naming the signed override, the built-but-never-armed third design, the ~30 defects found by four AI model families, the residual risk in one sentence, and 04-18-EXTERNAL-REVIEWS.md"
    - "04-18 and 04-19 have -PARTIAL.md stubs, NOT -SUMMARY.md, because phase-plan-index marks a plan complete on filename existence alone; 04-18's stub states prominently that it arms live SABnzbd config on a running container and must not be executed before its ~30 recorded defects are fixed"
    - "Nothing touches the estate: no ssh, no docker, no container command in any action or any verify; nscript_enable stays 0 and direct_unpack stays 1 because nothing goes near them"
    - "No credential reaches this public repo: added lines are materialised ONCE, the line count asserted non-zero before screening, and the positive control is injected into the REAL pipeline's input — and every screen uses grep -Ev/-Ec (ERE), because this workstation's grep is ugrep 7.8.4 where BRE \\+ after ^ is invalid, exits 2 and emits nothing, so every downstream stage reads empty and reports clean"
  artifacts:
    - path: ".planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md"
      provides: "The signed criterion-3 override: status passed, overrides_applied 1, accepted_by/accepted_at filled, reason amended to past tense, body byte-identical"
      contains: "Damian Flynn"
    - path: ".planning/ROADMAP.md"
      provides: "Phase 4 ticked with a signed-override completion note"
      contains: "signed override"
    - path: ".planning/STATE.md"
      provides: "completed_phases 5, percent 50, Current Position at Phase 5 NOT_STARTED"
      contains: "completed_phases: 5"
    - path: "stacks/selfhosted/arrs/beets.md"
      provides: "Dated supersession blockquotes closing criterion 3 by signed override, and a heading that no longer says interim status"
      contains: "04-18-EXTERNAL-REVIEWS.md"
    - path: ".planning/phases/04-collapse-to-one-tagger/04-18-PARTIAL.md"
      provides: "Not-executed stub carrying the danger warning about arming live SABnzbd config"
      contains: "MUST NOT BE EXECUTED"
    - path: ".planning/phases/04-collapse-to-one-tagger/04-19-PARTIAL.md"
      provides: "Not-executed stub recording supersession by quick task 260916-062"
      contains: "260916-062"
  key_links:
    - from: "04-VERIFICATION.md frontmatter overrides[0]"
      to: "the operator's signature"
      via: "a YAML safe_load of lines 2..N-1 only, asserting accepted_by == 'Damian Flynn'"
      pattern: "accepted_by: \"Damian Flynn\""
    - from: "ROADMAP line 52 tick"
      to: "the signed override record"
      via: "an in-line pointer to 04-VERIFICATION.md, stated as an override and not as a byte proof"
      pattern: "signed override"
    - from: "beets.md § The five criteria row 3"
      to: "the 2026-09-18 supersession blockquote"
      via: "a dated blockquote appended AFTER the table, leaving 'window 2: OPEN' intact as the record of the byte evidence"
      pattern: "^> \\*\\*Closed 2026-09-18"
---

<objective>
Phase 4 has been measurably finished for four days and is recorded as open, because the one thing
left was never a measurement. Criterion 3's behavioural half could not be proven at the byte level
after three capture designs; the third was built and self-tested in plan 04-17 and then deliberately
never armed, after four independent AI model families found roughly 30 defects in the plan that
would have armed it. Quick task 260916-062 prepared the override UNSIGNED and stopped, correctly,
because an agent cannot sign a policy call on the operator's behalf.

The operator has now signed it. Asked what closing Phase 4 requires and given five items, they
replied "please do all 5" — item 1 being the signature.

This plan performs that signature and reconciles every record that would otherwise contradict it:
the verification frontmatter, the override's own now-stale reason prose, the ROADMAP tick, STATE.md,
the estate's own `beets.md` page (frozen at window 2 and currently claiming criterion 3 OPEN under an
interim-status heading), and two not-executed plan stubs so a future session reading the phase
directory meets the record rather than a silence — 04-18 especially, which arms live SABnzbd config
on a running container and must not be run as written.

Purpose: close Phase 4 honestly. The phase closes at 5/5 with criterion 3 discharged by a **signed
override, not by a byte proof**, and every record must say exactly that — neither more nor less.
Output: six files changed in one commit, the estate untouched.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@.planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md
@.planning/ROADMAP.md
@./CLAUDE.md

Read as needed, not up front:
- `.planning/STATE.md` — **top only** (frontmatter + § Current Position, lines 1-48). The tail is
  stale historical narrative; it is not to be read, corrected or touched.
- `stacks/selfhosted/arrs/beets.md` — lines 1120-1260 only.
- `.planning/phases/04-collapse-to-one-tagger/04-18-EXTERNAL-REVIEWS.md` — pointer target; skim only
  if the stub text needs a defect count confirmed.

**Measured facts, recorded here so no task re-derives them:**
- `04-VERIFICATION.md` is 265 lines. `^---$` at lines **1, 106 and 262**. Frontmatter is lines
  **2-105**, between the FIRST and SECOND only. The third `---` at 262 is a body horizontal rule.
- Pre-edit body sha256, taken from the line after the second `---`:
  **`5a1c5fb11577693189ce59a8b28ca1e25cf491e4b16ba4e2d78aef17161c2b16`**
- `^overrides:` at column 1 matches **twice**: line 68 (frontmatter, the real one) and line 250
  (a prose draft inside a ```yaml fence in § Gaps Summary). `accepted_by:`/`accepted_at:` likewise
  match twice (104/105 real, 253/254 prose). **A whole-file grep cannot tell them apart. Use a
  YAML parse of the frontmatter region.**
- `python3` has PyYAML **6.0.3** available.
- `git config user.name` is **`Damian Flynn`**.
- `grep` on this workstation is **ugrep 7.8.4**.
- STATE.md stale-tail anchor `^\*\*02\.1-10 COMPLETE\.` matches exactly once (line 50); sha256 of
  that line to EOF is **`386c63cf3aadb2b6d3138447d95b3ac791a58fbaf1dd909aa62fa1318d738082`**.
- `beets.md` is 1305 lines: heading at **1126**, criterion-3 table row at **1226**, table ends 1228.
  `grep -nE 'window 3|04-17|override'` returns **zero** — the page is frozen at window 2.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Sign the override in the frontmatter, and amend the reason prose it makes stale</name>
  <files>.planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md</files>
  <action>
Four edits, all inside the frontmatter (lines 2-105). Use the Edit tool. Change nothing after the
second `---` at line 106.

1. Line 4: `status: gaps_found` → `status: passed`
2. Line 6: `overrides_applied: 0` → `overrides_applied: 1`
3. Lines 104-105: replace the two literal placeholders with exactly these values, which the operator
   instructed verbatim — no discretion, no email address, no alternative name or timestamp:
   `    accepted_by: "Damian Flynn"`
   `    accepted_at: "2026-09-18T07:36:35Z"`
   That timestamp is measured **true UTC**. Do NOT copy STATE.md's local-time-stamped-`Z`
   convention into it; that wart is pre-existing and documented, and an acceptance record has to
   carry a correct timestamp.
4. Amend the override's own `reason:` at lines 100-103. As written it reads as a live instruction —
   that `status` *stays* `gaps_found` and `overrides_applied` *stays* 0 until the operator signs —
   which the three edits above make false, leaving a sentence that contradicts the fields directly
   beside it. That is the same "comment stating the opposite of the record" defect this phase has
   already had to fix twice. Replace exactly these four lines:

       This override is
       **UNSIGNED** — prepared for the operator, not taken by the agent. `status` stays
       `gaps_found` and `overrides_applied` stays 0 until the operator fills `accepted_by` and
       `accepted_at` below.

   with exactly this, preserving the 6-space indentation of the folded `>` scalar:

       This override was
       **prepared UNSIGNED** by the agent, not taken by it, and **SIGNED by the operator on
       2026-09-18** on their explicit instruction. `status` moved from `gaps_found` to `passed` and
       `overrides_applied` from 0 to 1 at that signature, recorded in `accepted_by` and
       `accepted_at` below.

   Change nothing else in the reason: paragraphs (a) through (d) are the substance of the acceptance
   and stay verbatim. Add no prose claiming anything beyond acceptance — in particular do not write
   or imply that criterion 3 was proven.

Do not touch `gaps:`, `re_verification:`, `deferred:`, `score:`, or the prose draft at lines 249-255.
  </action>
  <verify>
    <automated>V=.planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md; END=$(grep -nE '^---$' "$V" | sed -n 2p | cut -d: -f1); BODY=$(tail -n +$((END+1)) "$V" | shasum -a 256 | cut -d' ' -f1); [ "$BODY" = 5a1c5fb11577693189ce59a8b28ca1e25cf491e4b16ba4e2d78aef17161c2b16 ] && echo "BODY-IDENTICAL" || { echo "BODY-CHANGED $BODY"; exit 1; }; sed -n "2,$((END-1))p" "$V" > /tmp/claude-501/-Users-damian-Development-damianflynn-selfhost-stacks/e978430b-edf0-415c-92ac-f2b6b679a5d1/scratchpad/fm.yaml; python3 -c "
import yaml,sys
d=yaml.safe_load(open('/tmp/claude-501/-Users-damian-Development-damianflynn-selfhost-stacks/e978430b-edf0-415c-92ac-f2b6b679a5d1/scratchpad/fm.yaml'))
o=d['overrides']
assert d['status']=='passed', d['status']
assert d['overrides_applied']==1, d['overrides_applied']
assert len(o)==1, len(o)
assert o[0]['accepted_by']=='Damian Flynn', o[0]['accepted_by']
assert str(o[0]['accepted_at'])=='2026-09-18T07:36:35Z', o[0]['accepted_at']
r=o[0]['reason']
assert 'until the operator fills' not in r, 'stale reason sentence survives'
assert 'stays' not in r.split('(d)')[-1] or True
assert 'SIGNED by the operator on' in r, 'signed-state sentence missing'
assert 'never armed' in r, 'reason substance lost'
print('FRONTMATTER-OK status=passed overrides_applied=1 signed=Damian Flynn')
"</automated>
  </verify>
  <done>Frontmatter YAML parses with `status: passed`, `overrides_applied: 1`, exactly one override signed `Damian Flynn` / `2026-09-18T07:36:35Z`; the reason no longer contains "until the operator fills" and does contain the past-tense signed-state sentence plus its (a)-(d) substance; body sha256 equals the pre-edit baseline.</done>
</task>

<task type="auto">
  <name>Task 2: Tick ROADMAP Phase 4 and advance STATE.md to Phase 5</name>
  <files>.planning/ROADMAP.md, .planning/STATE.md</files>
  <action>
**ROADMAP.md — one line only, line 52.** Replace:

`- [ ] **Phase 4: Collapse to One Tagger** - One tagger, one database, no idle container holding a rw mount — independently shippable`

with the same line ticked and carrying a completion note in the parenthetical style lines 49-51
already use:

`- [x] **Phase 4: Collapse to One Tagger** - One tagger, one database, no idle container holding a rw mount — independently shippable (closed 2026-09-18 at 5/5: criteria 1, 2, 4 and 5 verified by live measurement; **criterion 3 discharged by a signed override, not by a byte proof** — the operator accepted the threefold unanimous side-effect evidence (5 real music jobs, 2 observation windows, 0 tagger artefacts of any kind) in place of the PRE-HOOK/COMPLETION byte comparison the criterion's own evidence contract asks for, after three capture designs were built and exhausted and the third was deliberately never armed. Signed record: `.planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md`)`

Do not overstate it as a byte proof. Make **no other ROADMAP change** — not the 04-15/04-16/04-17
checkboxes, not the 04-18/04-19 rows and their not-executed notes, and no quick-task tracking.

**STATE.md — by hand with the Edit tool. Never a `gsd-sdk state.*` verb**: they are documented to
corrupt unrelated STATE.md lines. Five edits, all in lines 1-48:

- Line 6: `last_updated: "2026-09-16T00:25:00.000Z"` → `last_updated: "2026-09-18T07:36:35.000Z"`
- Line 7 `last_activity:` — replace the whole value with:
  `2026-09-18 -- quick 260918-byj CLOSED PHASE 4. The operator signed the criterion-3 override in 04-VERIFICATION.md's frontmatter (accepted_by Damian Flynn, accepted_at 2026-09-18T07:36:35Z; status gaps_found -> passed, overrides_applied 0 -> 1), so the phase closes at 5/5 with criterion 3 discharged by a SIGNED OVERRIDE, not by a byte proof. ROADMAP Phase 4 ticked; beets.md's interim-status section superseded in band; 04-18 and 04-19 recorded as -PARTIAL (never executed, nothing armed). ESTATE UNTOUCHED -- nscript_enable still 0, direct_unpack still 1; this task ran no estate command at all. Next: plan Phase 5 (Inbox Structure and the Junk Gate)`
- Line 10: `completed_phases: 4` → `completed_phases: 5`
- Line 13: `percent: 40` → `percent: 50`
- **`total_plans: 63` and `completed_plans: 61` stay exactly as they are.** 04-18 and 04-19 were
  never executed; inflating either would assert work that did not happen.
- Line 24: `**Current focus:** Phase 04 — collapse-to-one-tagger` →
  `**Current focus:** Phase 05 — inbox-structure-and-the-junk-gate`
- Lines 31-48 (the § Current Position body, from `Phase: 04 (collapse-to-one-tagger) — EXECUTING`
  through `estate command at all.`) — replace that whole block with:

      Phase: 05 (inbox-structure-and-the-junk-gate) — NOT_STARTED
      Plan: none yet — Phase 5 is unplanned. Run `/gsd-plan-phase 5`.
      Status: **Phase 4 CLOSED 2026-09-18 at 5/5 — criterion 3 discharged by a signed override, not
      by a byte proof.** Criteria 1, 2, 4 and 5 were verified by live measurement. Criterion 3's
      static half is measured (`grep -cE '^[[:space:]]*beet ' audio.bash` → 0, vendored-drift guard
      green); its behavioural half was never proven at the byte level. Three capture designs were
      built: the destination-tree poll (window 1), the incomplete-tree poll (window 2), and
      SABnzbd's own `pp` notification hook (built and self-tested in 04-17, all 14 synthetic
      controls passing, **never armed**). Window 3 was closed unrun after external review of plan
      04-18 by four independent AI model families found roughly 30 defects, including a judge binary
      that self-reports every PASS condition — reviews preserved verbatim at
      `.planning/phases/04-collapse-to-one-tagger/04-18-EXTERNAL-REVIEWS.md`. The operator signed
      the prepared override on 2026-09-18, accepting the threefold unanimous side-effect evidence
      (5 real jobs, 2 windows, 0 tagger artefacts) in its place. **Residual risk, stated once:** "no
      evidence of tagging" is not identical to "proven absence of tagging at the byte level".
      Plans 04-18 and 04-19 were never executed and are recorded as `-PARTIAL.md`, not `-SUMMARY.md`
      — `04-18` in particular arms live SABnzbd config on a running container and must not be run
      until its recorded defects are fixed.
      **ESTATE UNTOUCHED** — `nscript_enable` still 0, `direct_unpack` still 1.

Leave every line from the `**02.1-10 COMPLETE.` heading (line 50) to EOF alone. It is stale; it is
not this task's mandate, and correcting it would put unreviewed edits in this commit.
  </action>
  <verify>
    <automated>set -o pipefail; echo "== ROADMAP =="; grep -c '^- \[x\] \*\*Phase 4: Collapse to One Tagger\*\*' .planning/ROADMAP.md; grep -c '^- \[ \] \*\*Phase 4:' .planning/ROADMAP.md; sed -n '52p' .planning/ROADMAP.md | grep -Ec 'closed 2026-09-18 at 5/5'; sed -n '52p' .planning/ROADMAP.md | grep -Ec 'signed override, not by a byte proof'; sed -n '52p' .planning/ROADMAP.md | grep -Ec '04-VERIFICATION\.md'; echo "(expect 1 0 1 1 1)"; R=$(git diff --numstat .planning/ROADMAP.md | awk '{print $1"/"$2}'); echo "roadmap-numstat=$R (expect 1/1)"; echo "== STATE fields =="; sed -n '1,14p' .planning/STATE.md | grep -E 'completed_phases|completed_plans|total_plans|percent|last_updated'; echo "== STATE tail byte-identical =="; T=$(sed -n '/^\*\*02\.1-10 COMPLETE\./,$p' .planning/STATE.md | shasum -a 256 | cut -d' ' -f1); [ "$T" = 386c63cf3aadb2b6d3138447d95b3ac791a58fbaf1dd909aa62fa1318d738082 ] && echo "TAIL-IDENTICAL" || { echo "TAIL-CHANGED $T"; exit 1; }; echo "== STATE intended hunks only =="; git diff -U0 .planning/STATE.md > /tmp/claude-501/-Users-damian-Development-damianflynn-selfhost-stacks/e978430b-edf0-415c-92ac-f2b6b679a5d1/scratchpad/state.diff; grep -Ec '^-[^-]' /tmp/claude-501/-Users-damian-Development-damianflynn-selfhost-stacks/e978430b-edf0-415c-92ac-f2b6b679a5d1/scratchpad/state.diff; grep -E '^-[^-]' /tmp/claude-501/-Users-damian-Development-damianflynn-selfhost-stacks/e978430b-edf0-415c-92ac-f2b6b679a5d1/scratchpad/state.diff | grep -Ecv 'last_updated|last_activity|completed_phases: 4|percent: 40|Current focus|^-Phase: 04|^-Plan: 17|^-Status:|notification hook|four independent AI model families|judge binary|FAIL, and a restore contract|measurement\.|04-18-EXTERNAL-REVIEWS|disposition now sits|override|accepted_at. are literal|still 0, .overrides_applied|0 tagger artefacts|further can be measured|ESTATE UNTOUCHED|estate command at all|^-$|^-`\.planning'; echo "(last number must be 0 = every removed line was an intended one)"; grep -c 'completed_plans: 61' .planning/STATE.md; grep -c 'total_plans: 63' .planning/STATE.md; grep -c 'Phase: 05 (inbox-structure-and-the-junk-gate) — NOT_STARTED' .planning/STATE.md; echo "(expect 1 1 1)"; echo "== no other planning file touched =="; git diff --name-only | sort</automated>
  </verify>
  <done>ROADMAP line 52 is `- [x]` with the dated signed-override note pointing at 04-VERIFICATION.md and ROADMAP shows exactly 1 added / 1 removed line. STATE.md reads `completed_phases: 5`, `percent: 50`, `total_plans: 63`, `completed_plans: 61`; Current Position is Phase 05 NOT_STARTED; the stale tail sha256 equals `386c63cf…`; every removed line in `git diff -U0 .planning/STATE.md` falls in the intended set (final count 0).</done>
</task>

<task type="auto">
  <name>Task 3: Supersede beets.md in band, write the two not-executed stubs, screen for credentials, commit</name>
  <files>stacks/selfhosted/arrs/beets.md, .planning/phases/04-collapse-to-one-tagger/04-18-PARTIAL.md, .planning/phases/04-collapse-to-one-tagger/04-19-PARTIAL.md</files>
  <action>
**A. `stacks/selfhosted/arrs/beets.md` — heading change plus two appended dated blockquotes.**

This page is frozen at window 2 and would now contradict a closed phase. Use **the page's own
layering convention**: the existing 2026-09-14 text is a true statement about what was known then,
so it is preserved verbatim and superseded by dated blockquotes — exactly as the
`> **Superseded 2026-09-14 (code review WR-09).**` and `> **Corrected 2026-09-15 …**` blocks at
lines 1247 and 1256 already do. **Do not rewrite the interim prose. Do not edit the criterion-3
table row** — `window 2: OPEN` stays, because it remains the accurate record of the byte evidence.

A1. Line 1126 — the heading must stop saying "interim status". Replace:
`## Phase 4 — interim status (2026-09-14): criterion 3 OPEN`
with:
`## Phase 4 — closed 2026-09-18: criterion 3 discharged by a signed override, not by a byte proof`

A2. Insert a dated blockquote immediately after line 1190 (`.planning/phases/04-collapse-to-one-tagger/`,
the last line of the section's prose, before `### The census, executed`), separated by a blank line.
Write it in the estate's own voice, as a blockquote, carrying all of:
  - `**Closed 2026-09-18 (quick task 260918-byj).**` as the opening bold marker.
  - The section above stays as the record of what was known on 2026-09-14; it is not retracted, and
    everything it says about windows 1 and 2 still holds.
  - Criterion 3 is **closed by a signed override, not by a byte proof.** The operator signed it in
    `.planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md`'s frontmatter on 2026-09-18,
    accepting the threefold unanimous side-effect evidence (5 real jobs, 2 windows, 0 `library.blb`,
    0 `beets.log`, 0 new `.bak`, 0 `SUCCESS: Matched with beets`, `extended.conf` provably never
    written) in place of the PRE-HOOK/COMPLETION byte comparison.
  - A **third** capture design was built: SABnzbd's own `pp` notification hook, built and
    self-tested in plan **04-17** with **all 14 synthetic controls passing** — and **never armed**.
  - **Window 3 was abandoned**, not lost. External review of plan 04-18 by **four independent AI
    model families** found roughly **30 defects** in the arming plan, including an **unverified
    judge that self-reported every PASS condition**, an OPEN branch that could swallow a FAIL, and a
    restore contract that was count-checked rather than diffed. A PASS from that instrument would
    not have been trustworthy, which is the entire reason for running it, so the window was closed
    unrun rather than run for the appearance of measurement. Reviews:
    `.planning/phases/04-collapse-to-one-tagger/04-18-EXTERNAL-REVIEWS.md`.
  - The residual risk, in one sentence: **"no evidence of tagging" is not identical to "proven
    absence of tagging at the byte level".**
  - **The estate was never changed by any of this** — `nscript_enable` stayed 0 and `direct_unpack`
    stayed 1.

A3. Insert a second, shorter dated blockquote immediately after the § *The five criteria* table
(after line 1228, the criterion-5 row, before `### What keeps these true`), separated by a blank
line. It must open `> **Closed 2026-09-18 — row 3's disposition, superseded.**` and state that
`window 2: OPEN` above remains the accurate record of the *byte* evidence and is deliberately left
standing, that criterion 3's disposition is now **closed by the signed override** in
`04-VERIFICATION.md` rather than by a byte proof, and that the third design (04-17's `pp` hook, 14
controls passing) was never armed. One pointer to `04-18-EXTERNAL-REVIEWS.md`.

**B. The two not-executed stubs.** Use the Write tool. Name them **`-PARTIAL.md`, never
`-SUMMARY.md`**: `phase-plan-index` marks a plan complete on filename existence alone regardless of
frontmatter, so a `-SUMMARY.md` here would silently assert work that never happened.

`.planning/phases/04-collapse-to-one-tagger/04-18-PARTIAL.md` — frontmatter
`phase: 04-collapse-to-one-tagger`, `plan: 18`, `status: not_executed`, `executed: false`,
`requirements: [TAGR-04]`, `requirements-completed: []`, `date: 2026-09-16`. Body must state, with
the danger first and unmissable, because a future session reads the phase directory and not the
ROADMAP:
  - A top-line warning block containing the literal string **`MUST NOT BE EXECUTED`**: this plan
    **arms live SABnzbd configuration on a running container** (`nscript_enable=1`,
    `nscript_cats=music`, `nscript_prio_pp=1`) and must not be executed without first fixing the
    roughly 30 defects recorded in `04-18-EXTERNAL-REVIEWS.md` — among them an unverified judge
    binary that self-reports every PASS condition, an OPEN branch that can swallow a FAIL, and a
    restore contract that is count-checked rather than diffed and so can leave the estate re-armed.
    `quick-health-check.sh` carries **no `nscript_*` guard**, so an armed estate is undetectable by
    the routine check and a later SABnzbd UI settings save would persist it.
  - **Never started:** no task was executed, nothing was armed, no estate command was run.
    `nscript_enable` is still 0 and `direct_unpack` is still 1.
  - The dated reason (2026-09-16): window 3 was closed unrun after four independent AI model
    families reviewed this plan; a PASS from that instrument would not have been trustworthy.
  - Pointers: `04-18-EXTERNAL-REVIEWS.md`, quick task `260916-062`, and the closure record
    `04-VERIFICATION.md` (signed override, 2026-09-18).

`.planning/phases/04-collapse-to-one-tagger/04-19-PARTIAL.md` — same frontmatter shape with
`plan: 19`. Body: never started, no task executed; **superseded** — its only live branch was the
OPEN disposition, which quick task `260916-062` performed directly by preparing the unsigned
override in `04-VERIFICATION.md`'s frontmatter without window 3 ever running, and which the operator
then signed on 2026-09-18. Depended on 04-18, which was never executed. Pointers:
`04-18-EXTERNAL-REVIEWS.md`, `260916-062`, `04-VERIFICATION.md`.

**C. Credential screen over every added line, then commit.** This repo is **public**.
`git add -N` the two new stubs first, or the diff will not see them. Materialise the added lines
**once** to a file, **assert the line count is non-zero before screening** so "could not look" stays
distinct from "nothing is wrong", and inject the positive control **into the real pipeline's input
file** — a control that runs its own separate `printf | grep` proves only that the regex compiles,
which is the self-reporting-gate defect it exists to catch. Use `grep -Ev` / `grep -Ec` (**ERE**)
throughout: `grep` here is ugrep 7.8.4, where BRE `\+` after `^` is **invalid** — `grep -v '^\+\+\+'`
exits **2 and emits nothing**, so every downstream stage reads an empty stream and reports clean.

Commit all six files in one commit:
`docs(04): close Phase 4 — operator-signed criterion-3 override, records reconciled`

No `ssh`, no `docker`, no container command anywhere in this task, including in verification.
  </action>
  <verify>
    <automated>set -o pipefail; S=/tmp/claude-501/-Users-damian-Development-damianflynn-selfhost-stacks/e978430b-edf0-415c-92ac-f2b6b679a5d1/scratchpad; B=stacks/selfhosted/arrs/beets.md; echo "== A: beets.md =="; grep -c '^## Phase 4 — interim status' "$B"; grep -c '^## Phase 4 — closed 2026-09-18: criterion 3 discharged by a signed override, not by a byte proof' "$B"; echo "(expect 0 1)"; grep -Ec '^> \*\*Closed 2026-09-18' "$B"; echo "(expect 2)"; grep -Ec 'window 2: OPEN' "$B"; echo "(expect 1 — record left standing)"; grep -Ec '04-18-EXTERNAL-REVIEWS\.md' "$B"; grep -Ec 'never armed' "$B"; grep -Ec '14 synthetic controls' "$B"; grep -Ec 'proven absence of tagging at the byte level' "$B"; grep -Ec 'four independent AI model families' "$B"; echo "(each >= 1)"; ROW=$(grep -nE '^\| \*\*3 —' "$B" | cut -d: -f1); BQ=$(grep -nE '^> \*\*Closed 2026-09-18 — row 3' "$B" | cut -d: -f1); echo "row=$ROW superseding-bq=$BQ"; [ -n "$ROW" ] && [ -n "$BQ" ] && [ "$BQ" -gt "$ROW" ] && echo "ORDER-OK" || { echo "ORDER-BAD"; exit 1; }; echo "== B: stubs =="; ls .planning/phases/04-collapse-to-one-tagger/04-1[89]-PARTIAL.md; SUMS=$(ls .planning/phases/04-collapse-to-one-tagger/04-18-SUMMARY.md .planning/phases/04-collapse-to-one-tagger/04-19-SUMMARY.md 2>/dev/null | wc -l | tr -d ' '); [ "$SUMS" -eq 0 ] && echo "NO-SUMMARY-STUBS-OK" || { echo "FORBIDDEN -SUMMARY stub present ($SUMS)"; exit 1; }; grep -c 'MUST NOT BE EXECUTED' .planning/phases/04-collapse-to-one-tagger/04-18-PARTIAL.md; grep -Ec 'nscript_enable' .planning/phases/04-collapse-to-one-tagger/04-18-PARTIAL.md; grep -Ec '260916-062' .planning/phases/04-collapse-to-one-tagger/04-18-PARTIAL.md .planning/phases/04-collapse-to-one-tagger/04-19-PARTIAL.md; grep -Ec 'status: not_executed' .planning/phases/04-collapse-to-one-tagger/04-18-PARTIAL.md .planning/phases/04-collapse-to-one-tagger/04-19-PARTIAL.md; echo "== C: credential screen (ERE only; ugrep 7.8.4) =="; git add -N .planning/phases/04-collapse-to-one-tagger/04-18-PARTIAL.md .planning/phases/04-collapse-to-one-tagger/04-19-PARTIAL.md; git diff --unified=0 | grep -E '^\+' | grep -Ev '^\+\+\+' > "$S/added.txt"; RC=$?; N=$(wc -l < "$S/added.txt" | tr -d ' '); echo "extract-rc=$RC added-lines=$N"; [ "$RC" -le 1 ] || { echo "COULD-NOT-LOOK: extraction failed rc=$RC"; exit 1; }; [ "$N" -gt 0 ] || { echo "COULD-NOT-LOOK: zero added lines materialised"; exit 1; }; cp "$S/added.txt" "$S/added-pc.txt"; printf '+AWS_KEY=AKIAIOSFODNN7EXAMPLE\n+xc_password=plaintextvalue\n' >> "$S/added-pc.txt"; PAT='(AKIA[0-9A-Z]{16}|xc_password|ArrApiKey|discogs[._-]?user_token|BEGIN [A-Z ]*PRIVATE KEY|(api[_-]?key|secret|token|password)[[:space:]]*[=:][[:space:]]*[^[:space:]<`$]{8,})'; PC=$(grep -Ec "$PAT" "$S/added-pc.txt"); REAL=$(grep -Ec "$PAT" "$S/added.txt"); echo "positive-control-hits=$PC real-hits=$REAL"; [ $((PC-REAL)) -eq 2 ] || { echo "SCREEN-NOT-LIVE: control did not fire through the real pipeline"; exit 1; }; [ "$REAL" -eq 0 ] || { echo "CREDENTIAL SUSPECTED in added lines"; grep -En "$PAT" "$S/added.txt"; exit 1; }; echo "SCREEN-CLEAN (control fired, real=0)"; echo "== commit =="; git status --porcelain; git log --oneline -1</automated>
  </verify>
  <done>`beets.md` carries the closed-not-interim heading, two dated `> **Closed 2026-09-18` blockquotes (the row-3 one positioned after the criterion-3 row), `window 2: OPEN` still present exactly once, and the required tokens. Both `-PARTIAL.md` stubs exist with no `-SUMMARY.md` counterpart, 04-18's carrying `MUST NOT BE EXECUTED`. The credential screen materialised a non-zero added-line set, its planted control fired through that same input (PC − REAL = 2), and real hits = 0. One commit contains exactly the six files.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| working tree → public GitHub remote | Every added line becomes world-readable on push; this repo has already leaked a gateway password for ~6 months |
| plan text → future executor | A stub or ROADMAP note read later is acted on without re-deriving its evidence |
| agent → operator authority | Signing an acceptance record is a policy act the agent cannot take on its own initiative |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-Q-01 | Information disclosure | added lines pushed to a public repo | mitigate | Task 3C: materialise added lines once, assert non-zero count, value-based ERE screen, real-hits must be 0 |
| T-Q-02 | Spoofing (false green) | the credential screen itself | mitigate | Positive control injected into the real pipeline's input file; gate asserts PC − REAL == 2, so a screen that silently reads an empty stream fails |
| T-Q-03 | Tampering | `grep -v '^\+\+\+'` under ugrep 7.8.4 | mitigate | ERE (`grep -Ev`/`-Ec`) everywhere; extraction RC asserted ≤ 1 before any downstream stage runs |
| T-Q-04 | Repudiation | the acceptance record's own timestamp | mitigate | `accepted_at` is measured true UTC, explicitly not STATE.md's local-time-with-`Z` wart |
| T-Q-05 | Tampering | 04-VERIFICATION.md body while editing frontmatter | mitigate | Body sha256 compared to the recorded pre-edit baseline; frontmatter gated by YAML parse, never a whole-file grep (the line-250 prose draft satisfies `^overrides:`) |
| T-Q-06 | Elevation of privilege | plan 04-18 re-read later and run | mitigate | `-PARTIAL.md` not `-SUMMARY.md`, plus a `MUST NOT BE EXECUTED` warning naming the live-arming risk and the unguarded `nscript_*` state |
| T-Q-07 | Tampering | STATE.md's unrelated lines | mitigate | Hand-edited with Edit only, never `gsd-sdk state.*`; stale-tail sha256 asserted equal to `386c63cf…`; every removed line in `git diff -U0` matched against the intended set |
| T-Q-08 | Denial of service | the estate | accept | Documentation-only: no `ssh`, no `docker`, no container command in any action or verify; `nscript_enable` stays 0 and `direct_unpack` stays 1 because nothing goes near them |
| T-Q-SC | Tampering | package installs | accept | No package-manager install of any kind in this plan |
</threat_model>

<verification>
Run after all three tasks, from the repo root:

1. `python3 -c` YAML parse of `04-VERIFICATION.md`'s frontmatter region → `status: passed`,
   `overrides_applied: 1`, one override signed `Damian Flynn` / `2026-09-18T07:36:35Z`, reason free
   of "until the operator fills".
2. Body sha256 after the second `---` equals `5a1c5fb1157769…c2b16`.
3. `grep -c '^- \[x\] \*\*Phase 4: Collapse to One Tagger\*\*' .planning/ROADMAP.md` → 1, and
   `git diff --numstat .planning/ROADMAP.md` → `1 1`.
4. STATE.md: `completed_phases: 5`, `percent: 50`, `total_plans: 63`, `completed_plans: 61`, Phase 05
   NOT_STARTED, stale-tail sha256 `386c63cf…`.
5. `grep -c '^## Phase 4 — interim status' stacks/selfhosted/arrs/beets.md` → 0; two
   `> **Closed 2026-09-18` blockquotes; `window 2: OPEN` still 1.
6. Both `-PARTIAL.md` files exist; neither `04-18-SUMMARY.md` nor `04-19-SUMMARY.md` does.
7. Credential screen: added-line count > 0, control hits − real hits == 2, real hits == 0.
8. `git show --stat HEAD` lists exactly the six files and nothing else.
</verification>

<success_criteria>
- The criterion-3 override is signed in the frontmatter with the operator's instructed values; the
  document body is byte-identical to its pre-edit state.
- The override's `reason:` describes the signed state in the past tense and no longer reads as an
  instruction contradicting the fields beside it.
- ROADMAP Phase 4 is ticked with a note that says signed override, dated 2026-09-18, pointing at
  `04-VERIFICATION.md`, and claims no byte proof.
- STATE.md is at Phase 5 NOT_STARTED with 5/10 phases and 61/63 plans; its stale tail is untouched.
- `beets.md` no longer says "interim status" and no longer leaves criterion 3 at window 2; the
  2026-09-14 record survives verbatim, superseded by two dated blockquotes.
- `04-18-PARTIAL.md` and `04-19-PARTIAL.md` exist; 04-18's carries an unmissable
  `MUST NOT BE EXECUTED` warning about arming live SABnzbd config.
- One commit, six files, zero credentials, zero estate commands.
</success_criteria>

<output>
Create `.planning/quick/260918-byj-close-phase-4-sign-the-criterion-3-overr/260918-byj-SUMMARY.md`
when done.
</output>
