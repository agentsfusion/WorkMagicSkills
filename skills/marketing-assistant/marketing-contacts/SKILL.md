---
name: marketing-contacts
description: "Marketing contact list management: CRUD operations on customer data stored in Google Sheets via gws CLI. Use when: adding, updating, deleting, searching customer contacts; reading the customer list; filtering by company, status, or name. Triggers: customer list, 联系人, 添加客户, 删除客户, 更新客户, 查找客户, contacts, add customer, update customer."
triggers:
  - customer list
  - 联系人
  - 添加客户
  - 删除客户
  - 更新客户
  - 查找客户
  - contacts
  - add customer
  - update customer
---

# marketing-contacts

> **PREREQUISITE:** Load the `gws-shared` skill for auth, global flags, and security rules. The `gws` binary must be on `$PATH`.

Manage customer contacts stored in a Google Sheet. All operations go through the `gws` CLI.

## Configuration

```yaml
config:
  spreadsheet_id: "REPLACE_WITH_ACTUAL_ID"
  sheet_name: "CustomerList"
  primary_key: "Email"  # Column C
```

Override `spreadsheet_id` per invocation if the user specifies a different sheet.

## Schema Reference

The header row is **row 1**. Data starts at **row 2**.

| Column | Position | Type | Description |
|--------|----------|------|-------------|
| Customer Name | A | string | Full name |
| Company | B | string | Company name |
| Email | C | string | **Primary key** — must be unique |
| Phone | D | string | Phone number (optional) |
| Status | E | enum | One of: New, Contacted, Replied, Meeting Scheduled, Qualified, Closed Won, Closed Lost |
| Title | F | string | Job title |
| Last Contact Date | G | date | ISO date (YYYY-MM-DD) |
| Owner | H | string | Account owner |
| Notes | I | string | Free-text, append-only |

## Read Customers

### Read all

```bash
gws sheets +read --spreadsheet SPREADSHEET_ID --range "CustomerList"
```

### Filter by company, status, name, or keyword

Use the two-step pattern from `gws-json-filter`: save output to file, then filter with Python.

**Step 1 — Fetch and save (bash):**

```bash
gws sheets +read --spreadsheet SPREADSHEET_ID --range "CustomerList" --format json > _contacts_raw.json
```

**Step 2 — Filter (python):**

```python
import json, os, sys

filepath = '_contacts_raw.json'
if not os.path.exists(filepath):
    print("ERROR: file not found. Step 1 likely failed.")
    sys.exit(1)

with open(filepath) as f:
    content = f.read().strip()

# gws +read returns {values: [[...], ...]}
data = json.loads(content)
rows = data.get('values', [])
if not rows:
    print("No data found.")
    sys.exit(0)

header = rows[0]
records = [dict(zip(header, row)) for row in rows[1:]]

# Filter examples — uncomment/modify as needed:

# 1. Filter by company
matches = [r for r in records if "Acme" in r.get('Company', '')]

# 2. Filter by status
# matches = [r for r in records if r.get('Status', '') == 'New']

# 3. Keyword search across all fields
# keyword = "john"
# matches = [r for r in records if keyword.lower() in json.dumps(r).lower()]

for r in matches:
    print(f"{r.get('Email','')} | {r.get('Customer Name','')} | {r.get('Company','')} | {r.get('Status','')}")

print(f"\nFound {len(matches)} matching contact(s).")
os.remove(filepath)
```

## Add Customer

Uses `gws sheets +append`. Auto-fill `Status="New"` and `Last Contact Date` with today's date if the user doesn't provide them.

```bash
gws sheets +append --spreadsheet SPREADSHEET_ID \
  --range "CustomerList!A1" \
  --json-values '[["Jane Smith","Acme Corp","jane@acme.com","415-555-0100","New","VP Engineering","2026-04-20","Alice",""]]'
```

**Column order matters.** Always provide values in A-through-I order. Leave optional fields as empty strings.

> [!CAUTION]
> This is a **write** command. Confirm with the user before executing.

## Update Customer

Two-step process: read to find the row by Email, then update specific cells.

### Step 1 — Find row number by Email (python)

```python
import json, os, sys

filepath = '_contacts_raw.json'
if not os.path.exists(filepath):
    print("ERROR: file not found. Run gws +read first.")
    sys.exit(1)

with open(filepath) as f:
    data = json.loads(f.read())

rows = data.get('values', [])
if not rows:
    print("No data found.")
    sys.exit(0)

header = rows[0]
email_col = header.index('Email')  # Column C (index 2)
target_email = "jane@acme.com"

for i, row in enumerate(rows[1:], start=2):  # data starts at row 2
    if len(row) > email_col and row[email_col].lower() == target_email.lower():
        print(f"FOUND: row {i}, Email={row[email_col]}")
        print(f"Current data: {dict(zip(header, row))}")
        sys.exit(0)

print(f"No customer found with Email={target_email}")
```

### Step 2 — Update specific cells

Once you have the row number, update by column range:

```bash
# Update Status (column E) for row 3
gws sheets spreadsheets values update \
  --params '{"spreadsheetId":"SPREADSHEET_ID","range":"CustomerList!E3","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["Contacted"]]}'

# Update multiple fields (E through I) for row 3
gws sheets spreadsheets values update \
  --params '{"spreadsheetId":"SPREADSHEET_ID","range":"CustomerList!E3:I3","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["Contacted","","2026-04-20","","Updated after phone call"]]}'
```

**To append to Notes (column I)** without overwriting: read the current value first, then write the combined string.

> [!CAUTION]
> This is a **write** command. Confirm with the user before executing.

## Delete Customer

Clears row content (preserves row alignment). Does **not** delete the row itself.

### Step 1 — Find row number

Same as the Update step 1 above.

### Step 2 — Clear the row

```bash
# Clear columns A through I for row 3
gws sheets spreadsheets values clear \
  --params '{"spreadsheetId":"SPREADSHEET_ID","range":"CustomerList!A3:I3"}' \
  --json '{}'
```

> [!CAUTION]
> This is a **destructive** command. Confirm with the user before executing. Consider `--dry-run` first.

## Examples

### Example 1: List all customers with "New" status

```bash
# Step 1: Save to file
gws sheets +read --spreadsheet SPREADSHEET_ID --range "CustomerList" --format json > _contacts_raw.json

# Step 2: Filter for status=New (python)
# (use the filter script above with the status filter line uncommented)
```

### Example 2: Add a new customer

```bash
gws sheets +append --spreadsheet SPREADSHEET_ID \
  --range "CustomerList!A1" \
  --json-values '[["Bob Chen","TechStart Inc","bob@techstart.io","555-0199","New","CTO","2026-04-20","Alice","Met at SaaS conference"]]'
```

### Example 3: Update a customer's status to "Replied"

```bash
# Step 1: Read to find row
gws sheets +read --spreadsheet SPREADSHEET_ID --range "CustomerList" --format json > _contacts_raw.json
# (run Python row-finder with target email)

# Step 2: Update status (assume row 5)
gws sheets spreadsheets values update \
  --params '{"spreadsheetId":"SPREADSHEET_ID","range":"CustomerList!E5","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["Replied"]]}'
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `gws: command not found` | Install gws CLI and ensure it is on `$PATH` |
| `401 Unauthorized` | Run `gws auth login` or set `GOOGLE_APPLICATION_CREDENTIALS` |
| `404 Spreadheet not found` | Verify the spreadsheet ID in config |
| Append writes to wrong sheet | Add `--range "CustomerList!A1"` to target the correct tab |
| Update overwrites wrong row | Always read first to find the correct row number by Email |
| Row not found by Email | Check for typos or extra whitespace in the Email field |
| `!` causes shell errors | Wrap ranges in double quotes: `"CustomerList!A1:D10"` |
| Filter finds 0 results | Check header names match exactly (case-sensitive) |

## See Also

- `gws-shared` — Auth and global flags
- `gws-sheets-read` — Read values
- `gws-sheets-append` — Append rows
- `gws-sheets-update-values` — Update and clear values
- `gws-json-filter` — JSON filtering pattern
