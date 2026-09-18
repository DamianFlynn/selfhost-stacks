---
phase: 04-collapse-to-one-tagger
plan: 18
status: not_executed
executed: false
requirements: [TAGR-04]
requirements-completed: []
date: 2026-09-16
---

# Phase 4 Plan 18: NOT EXECUTED

> ## ⛔ MUST NOT BE EXECUTED AS WRITTEN
>
> This plan **arms live SABnzbd configuration on a running container** — it sets
> `nscript_enable=1`, `nscript_cats=music` and `nscript_prio_pp=1` in order to fire SABnzbd's own
> `pp` notification hook (the window-3 capture design built in plan 04-17).
>
> **Do not run it** without first fixing the roughly **30 defects** recorded in
> `04-18-EXTERNAL-REVIEWS.md`. Among them:
>
> - an **unverified judge binary that self-reports every PASS condition** — so a PASS from it is
>   not evidence of anything, which defeats the entire purpose of running the window;
> - an **OPEN branch that can swallow a FAIL**, reporting "could not look" where the correct
>   answer is "a condition was violated";
> - a **restore contract that is count-checked rather than diffed**, so it can report a clean
>   restore while **leaving the estate re-armed**.
>
> That last one is the dangerous one. `scripts/quick-health-check.sh` carries **no `nscript_*`
> guard**, so an estate left armed is **undetectable by the routine health check**, and a later
> SABnzbd UI settings save would persist the armed state permanently.

## Status: never started

**No task in this plan was executed. Nothing was armed. No estate command was run.**
`nscript_enable` is still `0` and `direct_unpack` is still `1`.

## Why it was not run (2026-09-16)

Plan 04-17 built the third capture design and **all 14 synthetic controls passed**. Plan 04-18 was
the plan that would have armed it against real music jobs. Before it ran, it was reviewed by **four
independent AI model families** (Claude, Google Gemini, GPT-5.5, Kimi-K3), which between them found
roughly 30 defects — see the warning above.

A PASS from that instrument would not have been trustworthy, **which is the entire reason for
running it**. Window 3 was therefore closed **unrun** rather than run for the appearance of
measurement. Abandoning the window was the cheaper and more honest of the two errors available.

## Pointers

- `.planning/phases/04-collapse-to-one-tagger/04-18-EXTERNAL-REVIEWS.md` — the four reviews,
  preserved verbatim.
- Quick task `260916-062` — prepared the criterion-3 override **unsigned** in
  `04-VERIFICATION.md`'s frontmatter and stopped there, correctly, because an agent cannot sign a
  policy call on the operator's behalf.
- `.planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md` — the closure record. The
  operator **signed** that override on **2026-09-18**, discharging criterion 3 by signed override
  rather than by a byte proof. Phase 4 closed at 5/5 on that signature, with this plan never run.
