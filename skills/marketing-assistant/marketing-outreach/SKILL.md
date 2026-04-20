---
name: marketing-outreach
description: "Email outreach: AI-compose personalized emails to customers via Gmail, send with human confirmation, auto-update contact status in Google Sheets. Use when: sending outreach emails, composing cold emails, contacting customers. Triggers: send email, 发邮件, 联系客户, outreach, cold email, 跟进邮件."
triggers:
  - send email
  - 发邮件
  - 联系客户
  - outreach
  - cold email
  - 跟进邮件
---

# marketing-outreach

Compose and send personalized outreach emails via Gmail, with automatic status updates to Google Sheets.

## Prerequisites

- `gws` CLI installed and on `$PATH`
- Authenticated via `gws auth login` (see `gws-shared` skill)
- A Google Sheet with the CustomerList schema (same sheet as `marketing-contacts`)

## Configuration

```yaml
config:
  spreadsheet_id: "DEFAULT_ID"  # overridable per invocation
  sheet_name: "CustomerList"
```

The user may provide a specific `spreadsheet_id`. If not, ask for one.

### CustomerList Schema

| Column | Field | Example |
|--------|-------|---------|
| A | Name | Jane Smith |
| B | Company | Acme Corp |
| C | Email | jane@acme.com |
| D | Phone | +1-555-0100 |
| E | Status | New |
| F | Title | VP Engineering |
| G | Last Contact Date | 2026-04-20 |
| H | Owner | sales@myco.com |
| I | Notes | Met at conference |

## Workflow

### Step 1: Read Customer Data

Fetch the customer row. If the user provides an email, search for that specific customer. Otherwise, read the full list and let the user pick.

```bash
# Read all customers
gws sheets +read --spreadsheet $ID --range "CustomerList"

# Read a specific row (if row number is known)
gws sheets +read --spreadsheet $ID --range "CustomerList!A3:I3"
```

Extract: **Name** (A), **Company** (B), **Email** (C), **Title** (F), **Notes** (I).

### Step 2: [Optional] Gather Research Context

If `marketing-research` output exists in the conversation, extract relevant talking points. If no research is available, proceed with customer data alone.

Research context enriches the email with:
- Recent company news or events
- Industry-specific talking points
- Conference or meeting references

### Step 3: AI Composes Email

Generate a personalized subject line and body following the **Email Composition Rules** below.

### Step 4: Present to User

Show the composed email (subject + body) and ask for approval. The user may:
- **Approve** as-is
- **Request edits** (tone, length, specific points)
- **Cancel** the send

### Step 5: Save as Draft

Always draft first. Never auto-send.

```bash
gws gmail +send --to "jane@acme.com" \
  --subject "Following up on Cloud Summit 2026" \
  --body "Hi Jane, ..." \
  --draft
```

### Step 6: Confirm and Send

After the user confirms the draft looks correct:

```bash
gws gmail +send --to "jane@acme.com" \
  --subject "Following up on Cloud Summit 2026" \
  --body "Hi Jane, ..."
```

Same command, but without `--draft`.

### Step 7: Auto-Update Sheet

After successful send, update the customer row. You must first read the current row to get the row number and existing Notes value.

```bash
# Read current notes (column I) to append, not overwrite
gws sheets +read --spreadsheet $ID --range "CustomerList!I3"

# Update Status (E), Last Contact Date (G), Notes (I)
gws sheets spreadsheets values update \
  --params '{"spreadsheetId":"ID","range":"CustomerList!E3:I3","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["Contacted","","2026-04-20","","Sent outreach: Following up on Cloud Summit 2026"]]}'
```

**Important**: When updating columns E through I, you must include all columns in the range. Columns you do not want to change should pass their current values. For Notes (I), always read the current value first and append the new note with a semicolon separator.

## Email Composition Rules

### Language

- Default: English
- Adjust if the customer's locale or previous correspondence suggests another language
- When in doubt, match the language of existing Notes

### Must Include

- Salutation with Name (and Title if available): "Hi Jane," or "Dear Ms. Smith, VP Engineering at Acme Corp,"
- At least one specific reference to the customer's company or role
- A clear, single call-to-action (meeting, call, reply)
- Professional closing with sender name

### Must Avoid

- Overly salesy or pushy tone ("Act now!", "Don't miss out!")
- Generic template feel ("I hope this email finds you well")
- Excessive length or multiple calls-to-action
- Attachments unless the user specifically requests them

### Target Length

150-250 words for the body. Keep it concise.

### Subject Line

- Concise (5-8 words)
- Specific to the customer's context (company name, event, topic)
- Never ALL CAPS or clickbait

## Auto-Update Rules

After a confirmed send, update exactly these fields:

| Column | Update To |
|--------|-----------|
| E (Status) | `Contacted` |
| G (Last Contact Date) | Today's date (ISO format: YYYY-MM-DD) |
| I (Notes) | Append "; Sent outreach: [subject]" to existing value |

### Notes Append Pattern

```
# Read existing notes
current_notes = read from column I

# Append new entry
if current_notes is empty:
    new_notes = "Sent outreach: [subject]"
else:
    new_notes = current_notes + "; Sent outreach: [subject]"
```

Never overwrite existing notes. Always append.

## Batch Mode

When the user wants to contact multiple customers:

1. Read the full customer list
2. Filter by criteria (e.g., Status="New", Company contains "Tech")
3. For each customer, run steps 3-7 individually
4. Compose unique, personalized emails for each customer (no copy-paste)
5. Present each email to the user before drafting
6. Track progress: report "3 of 8 sent" after each

```bash
# Example: batch update after sending to multiple customers
gws sheets spreadsheets values batchUpdate \
  --params '{"spreadsheetId":"ID"}' \
  --json '{
    "valueInputOption": "USER_ENTERED",
    "data": [
      {"range": "CustomerList!E3:I3", "values": [["Contacted","","2026-04-20","","Sent outreach: Topic A"]]},
      {"range": "CustomerList!E5:I5", "values": [["Contacted","","2026-04-20","","Sent outreach: Topic B"]]}
    ]
  }'
```

## Examples

### Example 1: Single Customer Outreach

User: "Send an email to john@acme.com about our new product"

```bash
# 1. Read customer data
gws sheets +read --spreadsheet $ID --range "CustomerList"

# Locate john@acme.com at row 4
# 2. AI composes email based on Name=John Doe, Company=Acme Corp, Title=CEO

# 3. Show email to user for approval

# 4. Draft
gws gmail +send --to "john@acme.com" \
  --subject "New data platform for Acme Corp" \
  --body "Hi John, ... personalized body ..." \
  --draft

# 5. User confirms → send
gws gmail +send --to "john@acme.com" \
  --subject "New data platform for Acme Corp" \
  --body "Hi John, ... personalized body ..."

# 6. Update sheet
gws sheets +read --spreadsheet $ID --range "CustomerList!I4"
# Read current notes, then:
gws sheets spreadsheets values update \
  --params '{"spreadsheetId":"ID","range":"CustomerList!E4:I4","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["Contacted","","2026-04-20","","Sent outreach: New data platform for Acme Corp"]]}'
```

### Example 2: Outreach With Research Context

User: "Reach out to the VP at TechCorp using the research we did earlier"

The conversation already contains `marketing-research` output about TechCorp's recent Series B funding.

```bash
# 1. Read customer data
gws sheets +read --spreadsheet $ID --range "CustomerList"

# Locate TechCorp VP at row 7
# 2. AI composes email referencing Series B funding from research

# 3. Draft with research-enriched content
gws gmail +send --to "sarah@techcorp.io" \
  --subject "Congrats on Series B, Sarah" \
  --body "Hi Sarah, ... congratulations on the Series B ... how we can help scale ..." \
  --draft

# 4-6: Same confirm → send → update flow
```

### Example 3: Batch Outreach to New Customers

User: "Send introductory emails to all New customers"

```bash
# 1. Read all customers
gws sheets +read --spreadsheet $ID --range "CustomerList"

# Filter where Status = "New" (column E)
# Found 3 new customers at rows 3, 5, 8

# 2. Compose unique emails for each
# 3. Present all 3 to user for review
# 4. Draft each one
gws gmail +send --to "alice@startup.com" --subject "..." --body "..." --draft
gws gmail +send --to "bob@scale.io" --subject "..." --body "..." --draft
gws gmail +send --to "carol@ventures.co" --subject "..." --body "..." --draft

# 5. User confirms all → send each without --draft

# 6. Batch update
gws sheets spreadsheets values batchUpdate \
  --params '{"spreadsheetId":"ID"}' \
  --json '{
    "valueInputOption": "USER_ENTERED",
    "data": [
      {"range": "CustomerList!E3:I3", "values": [["Contacted","","2026-04-20","","Sent outreach: intro email"]]},
      {"range": "CustomerList!E5:I5", "values": [["Contacted","","2026-04-20","","Sent outreach: intro email"]]},
      {"range": "CustomerList!E8:I8", "values": [["Contacted","","2026-04-20","","Sent outreach: intro email"]]}
    ]
  }'
```

## CAUTION

> [!CAUTION]
> **Always draft-first.** Every email must go through `--draft` before sending. Never auto-send without human review of the composed content. This is non-negotiable.
>
> After the user approves and the email is sent, always update the Sheet. If the Sheet update fails, inform the user so they can update manually.

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `gws: command not found` | gws not installed | Install gws CLI and ensure it is on `$PATH` |
| `auth error: invalid_grant` | Token expired | Run `gws auth login` to re-authenticate |
| Customer not found in Sheet | Email mismatch or missing row | Verify the email address; use `+read` with full range to search |
| Row update overwrites Notes | Used wrong range or didn't read first | Always read column I first, then include current value + append |
| Gmail rate limit hit | Too many sends in short period | Wait and retry; Gmail limit is ~100 emails/day for consumer accounts |
| `--draft` email not visible | Draft saved in a different label | Check Gmail "Drafts" folder; confirm the account matches `gws auth` |
| zsh `!` expansion error | Sheet range with `!` in zsh | Use double quotes for ranges: `--range "CustomerList!A1:I1"` |

## Dependencies

- `gws-gmail-send` — sending and drafting emails
- `gws-sheets-read` — reading customer data
- `gws-sheets-update-values` — updating status and notes
- `gws-shared` — auth, global flags, security rules
- `marketing-contacts` — customer data access patterns and schema
- `marketing-research` — optional research context consumed via conversation
