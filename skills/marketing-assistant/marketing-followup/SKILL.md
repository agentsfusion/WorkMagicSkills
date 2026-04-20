---
name: marketing-followup
description: "Follow-up monitor: check customer email replies via Gmail, AI-analyze content, suggest and update CRM status in Google Sheets. Use when: checking replies, analyzing responses, updating status based on replies. Triggers: check replies, 查看回复, follow up, 邮件回复, 更新状态."
triggers:
  - check replies
  - 查看回复
  - follow up
  - 邮件回复
  - 更新状态
---

# marketing-followup

Monitor customer email replies, AI-analyze content, and update CRM status in Google Sheets.

## Prerequisites

- `gws` CLI on `$PATH`. See `gws-shared` skill for auth setup.
- Authenticated via `gws auth login` or service account.
- Load the `gws-shared` skill before first use.

## Configuration

All marketing skills share one Google Sheet. Set these before running any command:

```
SPREADSHEET_ID = "<your-sheet-id>"   # Override per invocation if needed
SHEET_NAME     = "CustomerList"
```

## CustomerList Schema

| Column | Index | Description |
|--------|-------|-------------|
| A | Name | Contact full name |
| B | Company | Company name |
| C | Email | **Primary key**, unique |
| D | Phone | Phone number (optional) |
| E | Status | CRM status enum |
| F | Title | Job title |
| G | Last Contact Date | ISO date of last interaction |
| H | Owner | Account owner |
| I | Notes | Free-text, appended over time |

**Status values**: New, Contacted, Replied, Meeting Scheduled, Qualified, Closed Won, Closed Lost.

## Workflow

### Step 1: Read customers, filter by status

```bash
# Fetch all customers as JSON
gws sheets +read --spreadsheet "$SPREADSHEET_ID" --range "$SHEET_NAME" --format json > _customers.json
```

Then filter with Python to find rows where Status is `Contacted` or `Replied`:

```python
import json, os

with open('_customers.json') as f:
    raw = json.load(f)

rows = raw.get('values', [])
if not rows:
    print("No data found.")
    exit()

headers = rows[0]
data = [dict(zip(headers, row)) for row in rows[1:]]

targets = [r for r in data if r.get('Status') in ('Contacted', 'Replied')]
for r in targets:
    print(f"Row {rows.index(list(r.values())) + 1}: {r.get('Name')} | {r.get('Email')} | {r.get('Status')}")

os.remove('_customers.json')
```

### Step 2: Search for replies

For each customer, search Gmail for their replies:

```bash
gws gmail +triage --query "from:{customer_email}" --max 5
```

Example:

```bash
gws gmail +triage --query "from:john@acme.com" --max 5
```

If the output shows new messages since the last contact date, note the message ID.

### Step 3: Read the reply

```bash
gws gmail +read --id {message_id} --headers
```

Example:

```bash
gws gmail +read --id 18f1a2b3c4d --headers
```

### Step 4: AI analyzes reply

Extract from the reply:

- **Sentiment**: positive, neutral, negative, OOO (out of office)
- **Key questions**: what the customer asked
- **Action items**: meeting request, demo request, info request, decline
- **Suggested status**: based on the transition rules below

### Step 5: Suggest status update

Present to the user:

```
Customer: John Doe (john@acme.com)
Reply summary: Expressed interest in a product demo, asked about pricing.
Suggested status: Contacted → Replied
Suggested note: "Customer interested in demo, asked about pricing [date]"
```

Wait for user confirmation before proceeding.

### Step 6: User confirms, update Sheet

```bash
gws sheets spreadsheets values update \
  --params '{"spreadsheetId":"'"$SPREADSHEET_ID"'","range":"'"$SHEET_NAME"'!E{row}:I{row}","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["Replied","","2026-04-20","","Customer interested in demo, asked about pricing"]]}'
```

When updating Notes (column I), always **read the current value first** and **append** to it:

```bash
# Read current notes
gws sheets +read --spreadsheet "$SPREADSHEET_ID" --range "$SHEET_NAME!I{row}"
```

Then append the new note to the existing text before writing back.

## Status Transition Rules

**CRITICAL: Never downgrade status. Forward transitions only.**

| Signal | Transition | Notes |
|--------|-----------|-------|
| Positive interest, asks for more info | Contacted → Replied | Summarize key interest areas |
| Meeting, call, or demo mention | Replied → Meeting Scheduled | Capture proposed date/time |
| Decline / not interested | Contacted → Closed Lost | Note reason if given |
| No reply | No change | Report "no new reply" |
| Out of office / auto-reply | No change | Note return date in Notes |

Invalid transitions (FORBIDDEN):

- Replied → Contacted
- Meeting Scheduled → Replied
- Any backward move

## Reply Analysis Guide

When analyzing a reply, extract:

1. **Sentiment**: one of `positive`, `neutral`, `negative`, `ooo`
2. **Questions**: list any questions the customer asked
3. **Action items**: what the customer wants next (meeting, call, demo, more info, decline)
4. **Key quotes**: one or two relevant sentences from the reply
5. **Urgency**: high (meeting this week), medium (general interest), low (just acknowledging)

Present analysis in this format:

```
## Reply Analysis
- Customer: {Name} ({Email})
- Sentiment: {positive/neutral/negative/ooo}
- Questions: {list or "none"}
- Action items: {list or "none"}
- Suggested status: {current} → {next}
- Suggested note: "{summary} [{date}]"
```

## Batch Check

Check all Contacted customers at once:

1. Read customers, filter Status = `Contacted`
2. For each, run `gws gmail +triage --query "from:{email}" --max 3`
3. Collect all results, present a summary table:

```
| Customer | Email | Reply? | Suggested Status |
|----------|-------|--------|-----------------|
| John Doe | john@acme.com | Yes, positive | Replied |
| Jane Smith | jane@corp.io | No | No change |
| Bob Lee | bob@startup.co | OOO until 4/25 | No change |
```

4. Ask user which updates to apply, then batch-execute confirmed updates.

For batch updates, use `batchUpdate` to reduce API calls:

```bash
gws sheets spreadsheets values batchUpdate \
  --params '{"spreadsheetId":"'"$SPREADSHEET_ID"'"}' \
  --json '{
    "valueInputOption": "USER_ENTERED",
    "data": [
      {"range": "'"${SHEET_NAME}"'!E3:I3", "values": [["Replied","","2026-04-20","","Interested in demo"]]},
      {"range": "'"${SHEET_NAME}"'!E5:I5", "values": [["Replied","","2026-04-20","","Asked about enterprise pricing"]]}
    ]
  }'
```

## Idempotency

Before appending a note, check for duplicate entries:

1. Read current Notes value (column I for the target row)
2. Check if the proposed note text (or a very similar summary) already exists
3. If duplicate found, skip the append and report "note already recorded"
4. If no duplicate, append with the new note

This prevents duplicate Notes entries when running the follow-up check multiple times.

## Examples

### Scenario 1: Single customer reply check

User says: "Check if John Doe replied to our email"

```bash
# Step 1: Find John's row
gws sheets +read --spreadsheet "$SPREADSHEET_ID" --range "$SHEET_NAME" --format json > _customers.json
```

Filter to find John Doe's row number and email.

```bash
# Step 2: Search for replies
gws gmail +triage --query "from:john@acme.com" --max 5

# Step 3: Read the reply
gws gmail +read --id 18f1a2b3c4d --headers
```

AI analyzes: John expressed interest and asked about pricing. Suggest Contacted → Replied.

User confirms:

```bash
# Step 4: Update Sheet
gws sheets +read --spreadsheet "$SPREADSHEET_ID" --range "$SHEET_NAME!I3"
# Append new note to existing value

gws sheets spreadsheets values update \
  --params '{"spreadsheetId":"'"$SPREADSHEET_ID"'","range":"'"${SHEET_NAME}"'!E3:I3","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["Replied","","2026-04-20","","Interested in pricing; follow up next week"]]}'
```

### Scenario 2: Batch check all Contacted

User says: "Check replies from all contacted customers"

```bash
# Read all customers
gws sheets +read --spreadsheet "$SPREADSHEET_ID" --range "$SHEET_NAME" --format json > _customers.json
```

Filter to Status = Contacted. For each:

```bash
gws gmail +triage --query "from:jane@corp.io" --max 3
gws gmail +triage --query "from:bob@startup.co" --max 3
```

Present summary table. User selects which to update. Apply with `batchUpdate`.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `gws auth` error | Run `gws auth login` or set `GOOGLE_APPLICATION_CREDENTIALS` |
| No replies found | Customer may not have replied yet. Report "no new reply" and suggest checking again later |
| Rate limit from Gmail API | Space out requests. Use `--max 3` to limit results per query |
| Customer not found in Sheet | Verify Email column matches exactly. Email is case-insensitive but check for typos |
| Sheet range error | Confirm sheet name is `CustomerList`. Check `SPREADSHEET_ID` is correct |
| Duplicate notes appearing | Check existing Notes before appending. See Idempotency section |
| OOO auto-reply detected | Do not change status. Note the return date and suggest re-checking after that date |
| Status downgrade attempted | This is always wrong. Only forward transitions are allowed |
| `--params` on helper command | Helper commands (`+triage`, `+read`) use their own flags, not `--params`. See `gws-shared` skill |
