# Phase 3: Tagger Spike — Discussion Log

**Date:** 2026-08-24
**Purpose:** Human reference only (audits, retrospectives). Downstream agents read `03-CONTEXT.md`.

---

## Area selection

**Presented:** Versions under test · Discogs access · The 20-folder sample · Ergonomics scoring
**Selected:** all four.

Two facts surfaced during the scout that shaped the framing:
`stacks/selfhosted/music/wrtag.yaml:30` pins `sentriz/wrtag:v0.20.0`, and
`stacks/selfhosted/arrs/beets/beets.yaml:6` pins `lscr.io/linuxserver/beets:2.5.1-ls295` — eight
minors behind the researched 2.13.1. Both would have made a head-to-head invalid.

---

## Area 1 — Versions under test

**Q: Which wrtag version does the disqualifier test run against?**
Options: v0.33.0 (recommended) / both v0.20.0 and v0.33.0 / v0.20.0 as deployed.
**Chose:** v0.33.0 — the version we would actually run.

**Q: Which beets version?**
Options: 2.13.1 (recommended) / 2.5.1-ls295 as installed / defer the tag to plan time.
**Chose:** 2.13.1 — symmetry with the wrtag decision.

**Q: How should running untested-in-stack versions be staged?**
Options: throwaway containers with stack files untouched (recommended) / bump the stack files now /
bump only the winner afterwards.
**Chose:** throwaway containers, stack files untouched.

**Not asked, recorded as handoff:** the Renovate pin. TAGR-03 assigns it to Phase 4 and the spike's
result is the evidence that releases it.

---

## Area 2 — Discogs access

**Q: Where should the Discogs token live?**
Options: host-side git-ignored `.env` (recommended) / `~/.claude/secrets/` style / prompt each time.
**User response:** supplied the token value directly rather than choosing a location.

**Action taken:** written to `/mnt/fast/secrets/discogs.env` on LXC 100, mode `0600`, root-owned,
via stdin so the value never entered the host's process list. Verified live — `GET /oauth/identity`
returned HTTP 200 as `damian.flynn`, and `x-discogs-ratelimit: 60` confirmed the authenticated tier.
**Flagged to the user:** the value passed through a conversation transcript, so rotation on Discogs
is advised once the project completes. Not treated as an emergency — read-scoped personal token.

**Q: What counts as a "Discogs match" against the ~40% threshold?**
Options: candidate + track-count agreement (recommended) / any candidate at all / record both.
**Chose:** candidate AND track count agrees.

---

## Area 3 — The 20-folder sample

**Q: How should the ~20 DJ folders be chosen?**
Options: stratified across field-mapping variants (recommended) / the 27 with cover scans / random 20.
**Chose:** stratified across the variants.

**Q: On what, and how reversible, is the normalisation?**
Options: on copies (recommended) / in place relying on existing snapshots / in place after a fresh snapshot.
**Chose:** on copies, originals untouched.

**Q: Throwaway script, or the start of the real DJCC-01 tool?**
Options: throwaway but committed with dry-run (recommended) / build the mutagen tool properly now /
ad-hoc and uncommitted.
**Chose:** throwaway but committed and documented.

---

## Area 4 — Ergonomics scoring (TAGR-06)

**Q: How does "I will still open this in week six" become a recorded finding?**
Options: timed hands-on trial (recommended) / written rubric scored from docs / verdict recorded verbatim after the spike.
**Chose:** timed hands-on trial — the operator personally imports through each front end.

**Q: Which 5 albums does the trial use?**
Options: mixed 2 clean / 2 hard / 1 no-match (recommended) / five clean mainstream / five hard cases.
**Chose:** mixed.

---

## Closing question — remaining gray areas

**Offered:** ready for context / explore more (bucket A coverage, duplicate distortion of the match
rate, where beets-flask runs).

**User response instead:** *"This project is getting updates and attention
https://github.com/sentriz/wrtag its important to look at its tooling"*

**Investigated per the canonical-ref rule.** Findings:

1. **The inverted pin is confirmed from this repo's own config**, not from research. `wrtag.yaml:71`
   uses `.Release.Media`, `.Media.Position` and `.Track.Position` — all introduced in v0.30.0, none
   present in v0.20.x. `renovate.json5:91` holds wrtag at the one range its own path format cannot
   render. Latest is v0.33.0 (11 Jul 2026); v0.30.0 (8 Apr 2026) was the breaking release.
2. **wrtag ships a `metadata` tool the research missed** — reads *and writes* tags across multiple
   files and tags in one invocation, with wrtag's own normalisation, designed to pair with the
   subproc addon. The research's claim that wrtag has *"No facility"* for repairing existing wrong
   tags is **false**, and that was one of its two dominant arguments for beets.
3. **Still MusicBrainz-only** — no Discogs backend, checked against README and releases. The
   argument that does the real work survives.
4. `wrtag.yaml:73`'s `WRTAG_RESEARCH_LINK` already points at Discogs search — the existing config
   already concedes this content lives there, and offers a link rather than a lookup.

**Q: How should the spike handle the `metadata` finding?**
Options: add it as a third measured thing (recommended) / note it and keep to two axes / reopen the
whole beets-vs-wrtag case.
**Chose:** reopen it wider — re-examine the whole head-to-head.

**Tension flagged to the user rather than glossed:** the roadmap warns Phase 3 must "produce a
number, not relitigate a direction that four independent lines of evidence already agree on." The
choice cuts against that. Accepted on the basis that a premise was *demonstrably falsified* rather
than merely doubted — and scoped as a **claim-by-claim audit** (current source, verdict of
holds/falsified/changed, one-line impact) rather than a fresh direction essay, so it cannot become
open-ended relitigation. Recorded as D-12.

---

## Claude's discretion

- beets-flask image/tag and mount shape for the trial
- Scratch path naming under `tank/downloads`
- The claim-audit table's exact shape
- Whether `metadata` is exercised via the wrtag container or as a static binary

## Deferred

DJCC-01 full field-mapping tool (v2) · Renovate pin release (Phase 4) · bucket A coverage
measurement (assumed, not measured) · DUPE-01/02 roadmap decision before Phase 7 · TV subtree on
orphan gid 545.
