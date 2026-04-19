---
name: gws-calendar-update
description: "Google Calendar: Update or patch an existing event. Use when modifying event title, time, location, attendees, description, recurrence, reminders, or other event properties."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws calendar events update --help"
---

# calendar — update events

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

Update or patch an existing event on a Google Calendar.

## Commands

### Patch an event (partial update)

Changes only the fields you specify. All other fields remain unchanged. Use `events.patch` for most updates — it is safer and more concise than `events.update`.

```bash
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "EVENT_ID"}' \
  --json '{"summary": "Updated Title"}'
```

### Update an event (full replacement)

Replaces the **entire** event resource. Any field omitted from the request body is **removed**. Use only when you want to overwrite the event completely.

```bash
gws calendar events update \
  --params '{"calendarId": "primary", "eventId": "EVENT_ID"}' \
  --json '{
    "summary": "Team Standup",
    "start": {"dateTime": "2026-06-17T10:00:00", "timeZone": "America/Los_Angeles"},
    "end": {"dateTime": "2026-06-17T10:30:00", "timeZone": "America/Los_Angeles"},
    "location": "Room 3A",
    "attendees": [{"email": "alice@example.com"}, {"email": "bob@example.com"}]
  }'
```

## Key Parameters

### Path parameters (`--params`)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `calendarId` | ✓ | Calendar ID (use `primary` for the user's primary calendar) |
| `eventId` | ✓ | The event ID to update |

### Optional query parameters (`--params`)

| Parameter | Description |
|-----------|-------------|
| `sendUpdates` | Who to notify: `all` (default), `externalOnly`, `none` |
| `conferenceDataVersion` | `1` to enable conference data changes (e.g. Meet link updates) |
| `maxAttendees` | Max attendees to include in the response |

### Request body (`--json`)

| Field | Type | Description |
|-------|------|-------------|
| `summary` | `string` | Event title |
| `location` | `string` | Event location (free text) |
| `description` | `string` | Event description (supports HTML) |
| `start` | `object` | `{"dateTime": "2026-06-17T10:00:00", "timeZone": "America/Los_Angeles"}` or `{"date": "2026-06-17"}` for all-day |
| `end` | `object` | Same format as `start` |
| `attendees` | `array` | `[{"email": "user@example.com"}]` — omit to keep existing attendees in `patch` |
| `recurrence` | `array<string>` | RRULE, EXRULE, RDATE, EXDATE lines (e.g. `["RRULE:FREQ=WEEKLY;COUNT=10"]`) |
| `reminders` | `object` | `{"useDefault": false, "overrides": [{"method": "email", "minutes": 30}]}` |
| `colorId` | `string` | Color ID (1–11). Use `gws calendar colors get` to list available colors. |
| `visibility` | `string` | `default`, `public`, `private`, or `confidential` |
| `status` | `string` | `confirmed`, `tentative`, or `cancelled` |
| `conferenceData` | `object` | Add/remove video conference (e.g. Google Meet). Requires `conferenceDataVersion: 1` in params. |

## Common Patterns

### Change the event title

```bash
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "EVENT_ID"}' \
  --json '{"summary": "New Title"}'
```

### Reschedule an event

```bash
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "EVENT_ID"}' \
  --json '{
    "start": {"dateTime": "2026-06-18T14:00:00", "timeZone": "America/Los_Angeles"},
    "end": {"dateTime": "2026-06-18T15:00:00", "timeZone": "America/Los_Angeles"}
  }'
```

### Convert a timed event to all-day

```bash
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "EVENT_ID"}' \
  --json '{"start": {"date": "2026-06-18"}, "end": {"date": "2026-06-19"}}'
```

### Add attendees and notify them

```bash
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "EVENT_ID", "sendUpdates": "all"}' \
  --json '{"attendees": [{"email": "alice@example.com"}, {"email": "bob@example.com"}]}'
```

> [!WARNING]
> For `events.patch`, the `attendees` array **replaces** the entire list. To add one attendee without removing others, include all existing attendees plus the new one.

### Update without notifying attendees

```bash
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "EVENT_ID", "sendUpdates": "none"}' \
  --json '{"location": "Building 4, Room 201"}'
```

### Add a Google Meet link

```bash
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "EVENT_ID", "conferenceDataVersion": 1}' \
  --json '{
    "conferenceData": {
      "createRequest": {
        "requestId": "random-unique-string",
        "conferenceSolutionKey": {"type": "hangoutsMeet"}
      }
    }
  }'
```

### Update a recurring event

```bash
# Update the recurring series (all future instances)
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "RECURRING_EVENT_ID"}' \
  --json '{"summary": "Weekly Sync (Renamed)"}'

# Update a single instance
gws calendar events instances \
  --params '{"calendarId": "primary", "eventId": "RECURRING_EVENT_ID"}'
# Then patch the specific instance ID
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "INSTANCE_EVENT_ID"}' \
  --json '{"start": {"dateTime": "2026-06-18T15:00:00", "timeZone": "America/Los_Angeles"}}'
```

### Cancel (but don't delete) an event

```bash
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "EVENT_ID", "sendUpdates": "all"}' \
  --json '{"status": "cancelled"}'
```

### Find an event ID before updating

```bash
# List recent events and extract IDs
gws calendar events list \
  --params '{"calendarId": "primary", "maxResults": 10, "orderBy": "startTime", "singleEvents": true}' \
  --format json | jq '.[] | {id, summary, start}'
```

## patch vs update

| | `events.patch` | `events.update` |
|---|---|---|
| HTTP method | `PATCH` | `PUT` |
| Behavior | Merges specified fields into existing event | Replaces the entire event resource |
| Omitted fields | Left unchanged | **Removed** (reset to default) |
| Recommended for | Most updates | Full event replacement |
| Risk | Low | High — accidental data loss if fields are omitted |

## Tips

- Prefer `events.patch` over `events.update` — it is safer and requires fewer fields.
- Use `--dry-run` to preview the request without sending it.
- Use `gws schema calendar.events.patch` or `gws schema calendar.events.update` to inspect all available fields.
- Use `gws calendar colors get` to list available `colorId` values.
- For timezone-aware times, include the `timeZone` field in `start`/`end` objects, or use UTC offsets (e.g. `2026-06-17T10:00:00-07:00`).
- When updating attendees via `patch`, the `attendees` array replaces the entire list — fetch existing attendees first if you want to preserve them.
- Use `sendUpdates: "none"` when making minor changes that don't warrant notifications.

> [!CAUTION]
> These are **write** commands — confirm with the user before executing.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-calendar](../gws-calendar/SKILL.md) — All Calendar commands
- [gws-calendar-insert](../gws-calendar-insert/SKILL.md) — Create a new event
- [gws-calendar-agenda](../gws-calendar-agenda/SKILL.md) — Show upcoming events
