---
name: gws-sheets-update-values
description: "Google Sheets: Update and clear cell values in a spreadsheet."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws sheets spreadsheets values --help"
---

# sheets — update values

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

Update or clear cell values in a Google Sheets spreadsheet.

> **Full command path required:** Every command must include the complete nested resource path:
> `gws sheets spreadsheets values <method>` — do **NOT** omit `spreadsheets`.

## Commands

### Update a single range

Overwrites values in a specified range. Required params: `spreadsheetId`, `range`. The request body must include a `values` array.

```bash
gws sheets spreadsheets values update \
  --params '{"spreadsheetId": "SPREADSHEET_ID", "range": "Sheet1!A1:B2", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["Name", "Score"], ["Alice", 95]]}'
```

### Batch update multiple ranges

Updates values across multiple ranges in a single request. More efficient than multiple individual updates.

```bash
gws sheets spreadsheets values batchUpdate \
  --params '{"spreadsheetId": "SPREADSHEET_ID"}' \
  --json '{
    "valueInputOption": "USER_ENTERED",
    "data": [
      {"range": "Sheet1!A1:B2", "values": [["Name", "Score"], ["Alice", 95]]},
      {"range": "Sheet1!D1:D2", "values": [["Status"], ["Complete"]]}
    ]
  }'
```

### Clear a single range

Clears values only — formatting, data validation, and other cell properties are preserved.

```bash
gws sheets spreadsheets values clear \
  --params '{"spreadsheetId": "SPREADSHEET_ID", "range": "Sheet1!A1:B10"}' \
  --json '{}'
```

### Batch clear multiple ranges

Clears values from multiple ranges in a single request.

```bash
gws sheets spreadsheets values batchClear \
  --params '{"spreadsheetId": "SPREADSHEET_ID"}' \
  --json '{"ranges": ["Sheet1!A1:B10", "Sheet1!D1:D10"]}'
```

## Key Parameters

### values.update

| Parameter | Required | Description |
|-----------|----------|-------------|
| `spreadsheetId` | ✓ | The ID of the spreadsheet |
| `range` | ✓ | A1 notation range to update (e.g. `Sheet1!A1:B2`) |
| `valueInputOption` | — | How to interpret input: `RAW` (literal) or `USER_ENTERED` (parsed as if typed). Default: `RAW` |
| `includeValuesInResponse` | — | Return updated values in response (default: false) |

### Request body (`--json`)

| Field | Type | Description |
|-------|------|-------------|
| `values` | `array<array>` | The data to write. Outer array = rows, inner array = cell values |
| `range` | `string` | The range to write (optional in body; required in params) |
| `majorDimension` | `string` | `ROWS` (default) or `COLUMNS` — how to interpret the values array |

### values.batchUpdate

| Parameter | Required | Description |
|-----------|----------|-------------|
| `spreadsheetId` | ✓ | The ID of the spreadsheet |

### Request body (`--json`)

| Field | Type | Description |
|-------|------|-------------|
| `data` | `array<ValueRange>` | Array of `{range, values}` objects, one per range |
| `valueInputOption` | `string` | `RAW` or `USER_ENTERED` — applies to all ranges |

## Common Patterns

### Update a single cell

```bash
gws sheets spreadsheets values update \
  --params '{"spreadsheetId": "ID", "range": "Sheet1!A1", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["Hello"]]}'
```

### Update an entire row

```bash
gws sheets spreadsheets values update \
  --params '{"spreadsheetId": "ID", "range": "Sheet1!A1:D1", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["Alice", 95, "A", "Complete"]]}'
```

### Update multiple non-adjacent ranges at once

```bash
gws sheets spreadsheets values batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "valueInputOption": "USER_ENTERED",
    "data": [
      {"range": "Summary!A1", "values": [["Updated"]]},
      {"range": "Data!B2:B5", "values": [[10],[20],[30],[40]]}
    ]
  }'
```

### Clear and rewrite a table

```bash
# Step 1: Clear the old data
gws sheets spreadsheets values clear \
  --params '{"spreadsheetId": "ID", "range": "Sheet1!A1:C10"}' \
  --json '{}'

# Step 2: Write new data
gws sheets spreadsheets values update \
  --params '{"spreadsheetId": "ID", "range": "Sheet1!A1", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["Name","Score","Status"],["Bob",88,"Pass"]]}'
```

## valueInputOption — When to Use What

| Option | Behavior | Use When |
|--------|----------|----------|
| `USER_ENTERED` | Parsed as if typed into the UI — dates become dates, formulas start with `=` | Writing formulas, dates, numbers (most common) |
| `RAW` | Stored exactly as provided — no parsing | Writing literal strings that look like formulas or dates |

## Tips

- Always wrap range values in **single quotes** in bash ( Sheets `!` triggers history expansion).
- Use `--dry-run` to preview the request without sending it.
- `values.update` **overwrites** — it does not append. For appending, use `+append`.
- Response includes `updatedCells`, `updatedRows`, `updatedColumns` counts.
- For reading first (e.g. find-then-update), use [`+read`](../gws-sheets-read/SKILL.md).

> [!CAUTION]
> These are **write** commands — confirm with the user before executing.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-sheets](../gws-sheets/SKILL.md) — All Sheets commands
- [gws-sheets-append](../gws-sheets-append/SKILL.md) — Append rows
- [gws-sheets-read](../gws-sheets-read/SKILL.md) — Read values
- [gws-sheets-update-format](../gws-sheets-update-format/SKILL.md) — Format cells
- [gws-sheets-update-structure](../gws-sheets-update-structure/SKILL.md) — Add/delete sheets, resize
