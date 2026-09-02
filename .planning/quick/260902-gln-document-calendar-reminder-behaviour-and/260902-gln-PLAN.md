---
quick_id: 260902-gln
description: Document who gets reminders for Keeper-created events, and plan the Work-calendar split
date: 2026-09-02
status: in-progress
---

# Quick Task 260902-gln: Reminder behaviour on shared destination calendars

## Trigger

Breege, who has access to the Family calendar, reported daily reminder emails for every
Innofactor work meeting. This is a direct and undocumented consequence of the `Work → Family`
sync rule: the README explains what syncs where, but says nothing about who gets *notified*.

## Measured ground truth (2026-09-02)

**Keeper never sets reminders.** Verified by string count across all three service images:

```
cal-worker   reminders=0
cal-cron     reminders=0
cal-api      reminders=0
```

No reminder/notification columns in the schema either — the only match across all 24 tables is
`calendar_push_channels.lastNotificationAt`, which is internal change-detection plumbing.

**Therefore:** Keeper inserts events via the Google API with no `reminders` block. Google treats
an absent block as `reminders.useDefault = true`, so **each viewer's own per-calendar
notification settings decide what they receive.** Google's own docs confirm these settings are
"personal and apply only to your account" and "don't affect the notifications of others".

**Consequence:** every person with access to a destination calendar gets notified according to
*their* defaults, for events they did not create and cannot control. Nothing on the Keeper side
or the calendar-owner side can suppress this for another user.

**Not update churn.** 53 of 54 sync cycles on Family in 24h were pure no-ops
(`operations.total: 0`, `mapping_updates.count: 0`). The steady-state emails are Google's
Daily agenda, not change notifications.

**One-off burst caused by the 2.23 upgrade.** At `2026-09-02T09:52:46Z` — during the
2.13 → 2.23 upgrade performed in quick task 260902-fxf — the wider ingest window produced
`add_count: 185, remove_count: 48` on Family, and the identical burst on Personal at
`09:52:39Z`. Anyone with "New events → Email" on those calendars received up to 185 emails.
This is worth recording because the same thing will happen on any future re-ingest.

## Decisions (locked)

Route **A now, B later**:
- **A (now):** the affected user silences the calendar in their own Google settings. No
  infrastructure change. Cost: also silences genuine family events.
- **B (later):** give Work its own Google calendar, shared read-only, and repoint the Keeper
  rule. Keeps Family reminders intact while silencing work meetings.

## Tasks

### Task 1 — Document reminder behaviour in the keeper README
**Files:** `stacks/selfhosted/keeper-sh/README.md`
**Action:** Add a subsection under the privacy/topology discussion covering:
- Keeper sets no reminders; viewers' own defaults apply (with the verification method)
- Settings are per-user *and* per-calendar, so the calendar owner cannot fix it for a viewer
- A shared calendar appears under **"Settings for other calendars"** in the viewer's settings,
  not "Settings for my calendars" — the single most common reason people report the Daily
  agenda option as "missing"
- Must be done at `calendar.google.com`; the mobile apps keep separate notification state
- Re-ingest bursts (like the 2.23 upgrade) generate one email per created event for anyone
  with "New events → Email"
**Verify:** Section present, claims match the measured evidence above.
**Done:** A reader hitting this complaint can diagnose and fix it without re-deriving anything.

### Task 2 — Record the Work-calendar split as a planned change
**Files:** `stacks/selfhosted/keeper-sh/README.md`
**Action:** Add a short "Planned: split Work onto its own calendar" note capturing the design,
the two open risks, and the required sequencing:
- Unknown: whether deleting a Keeper sync rule cleans up the destination events it created or
  orphans them. **Must be tested on a throwaway calendar first.**
- The migration itself deletes ~185 events from Family and creates them elsewhere → a
  notification burst on both calendars. Silence notifications *before* migrating.
**Verify:** Note present with both risks stated.
**Done:** The follow-up is captured in the doc rather than living only in chat.

## Must-haves

- **Truths:** README states that Keeper sets no reminders and that viewer defaults govern; no
  claim contradicts the measured zero-occurrence evidence.
- **Artifacts:** reminder subsection + planned-change note in the keeper README.
- **Key links:** `stacks/selfhosted/keeper-sh/README.md`.

## Out of scope

- Executing the Work-calendar split (option B) — deferred by decision.
- Changing anything in Breege's Google account — not accessible from here, and per-user
  settings can only be changed while signed in as her.
