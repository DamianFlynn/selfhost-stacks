---
quick_id: 260902-gln
description: Document who gets reminders for Keeper-created events, and plan the Work-calendar split
date: 2026-09-02
status: complete
---

# Quick Task 260902-gln — Summary

## Trigger

Breege, who has access to the Family calendar, reported daily reminder emails for every
Innofactor work meeting. The README documented what syncs where but nothing about who gets
*notified* — a real gap, since the `Work → Family` rule pushes work meetings onto a calendar
other people can see.

## Root cause (measured, not assumed)

**Keeper sets no reminders.** `grep -roh reminders /app | wc -l` returns **0** in `cal-worker`,
`cal-cron` and `cal-api`. The schema has no reminder or notification column across all 24 tables
(only `calendar_push_channels.lastNotificationAt`, internal change-detection plumbing).

Keeper therefore inserts events with no `reminders` block, the Google API applies
`reminders.useDefault = true`, and **each viewer's own per-calendar notification settings govern
what they receive**. Google's settings are personal and do not affect other users — so the
calendar owner cannot fix it for a viewer; it must be changed while signed in as that person.

**Ruled out — update churn.** 53 of 54 sync cycles on Family in 24h were pure no-ops
(`operations.total: 0`, `mapping_updates.count: 0`). The recurring emails are Google's Daily
agenda, not change notifications.

**Self-inflicted contribution.** At `2026-09-02T09:52:46Z`, during the 2.13 → 2.23 upgrade in
quick task 260902-fxf, the wider ingest window produced `add_count: 185, remove_count: 48` on
Family and the same on Personal. Anyone with "New events → Email" received up to 185 emails.
That burst is very likely why the complaint surfaced today rather than weeks ago.

## What was done

Added a **"Reminders belong to the viewer, not to Keeper"** subsection to the keeper README
covering the mechanism, the verification command (re-run and confirmed to reproduce exactly as
written), and the fix click-path — including the gotcha that a calendar shared *with* you appears
under **"Settings for other calendars"**, not "Settings for my calendars", which is the usual
reason people report the Daily agenda option as missing. Also noted that the mobile apps keep
separate notification state, and that re-ingest bursts send one email per created event.

Recorded the **Work-calendar split** as a planned change with both open risks: it is unknown
whether deleting a Keeper sync rule cleans up its destination events or orphans them (test on a
throwaway calendar first), and the migration itself is another notification burst (silence first,
then migrate).

## Decision

Route **A now, B later** — the affected user silences the calendar today; the calendar split is
deferred to its own piece of work.

## Follow-ups

1. **Execute the Work-calendar split (option B)** — deferred by decision. Requires creating and
   sharing a Google calendar (not doable from here), plus the rule-deletion test above.
2. **Warn shared-calendar users before any keeper upgrade or ingest-window change** — the 185-event
   burst pattern will recur.
