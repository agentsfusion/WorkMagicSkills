---
name: gws-sheets-update-structure
description: "Google Sheets: Add/delete sheets, resize rows/columns, freeze panes, and modify spreadsheet structure."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws sheets spreadsheets batchUpdate --help"
---

# sheets — update structure

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

Modify the structural elements of a spreadsheet: add/remove sheets, resize rows and columns, freeze panes, and more. All structural changes use the `spreadsheets.batchUpdate` endpoint.

## Core Command

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "SPREADSHEET_ID"}' \
  --json '{"requests": [ ... ]}'
```

The `requests` array contains one or more request objects. All requests in the array are applied atomically — if any fails, none are applied.

## Operations

### Add a new sheet

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "addSheet": {
        "properties": {
          "title": "Q1 Report",
          "index": 0
        }
      }
    }]
  }'
```

Response includes `addSheet.properties.sheetId` — the numeric ID of the new sheet.

### Delete a sheet

You need the numeric `sheetId` (not the title). Get it from `sheets.spreadsheets.get`.

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "deleteSheet": {
        "sheetId": 123456789
      }
    }]
  }'
```

### Rename a sheet

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "updateSheetProperties": {
        "properties": {
          "sheetId": 0,
          "title": "New Name"
        },
        "fields": "title"
      }
    }]
  }'
```

### Resize columns

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "updateDimensionProperties": {
        "range": {
          "sheetId": 0,
          "dimension": "COLUMNS",
          "startIndex": 0,
          "endIndex": 5
        },
        "properties": {
          "pixelSize": 150
        },
        "fields": "pixelSize"
      }
    }]
  }'
```

### Resize rows

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "updateDimensionProperties": {
        "range": {
          "sheetId": 0,
          "dimension": "ROWS",
          "startIndex": 0,
          "endIndex": 10
        },
        "properties": {
          "pixelSize": 40
        },
        "fields": "pixelSize"
      }
    }]
  }'
```

### Auto-resize columns (fit to content)

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "autoResizeDimensions": {
        "dimensions": {
          "sheetId": 0,
          "dimension": "COLUMNS",
          "startIndex": 0,
          "endIndex": 5
        }
      }
    }]
  }'
```

### Freeze rows and/or columns

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "updateSheetProperties": {
        "properties": {
          "sheetId": 0,
          "gridProperties": {
            "frozenRowCount": 1,
            "frozenColumnCount": 2
          }
        },
        "fields": "gridProperties.frozenRowCount,gridProperties.frozenColumnCount"
      }
    }]
  }'
```

### Insert rows

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "insertDimension": {
        "range": {
          "sheetId": 0,
          "dimension": "ROWS",
          "startIndex": 3,
          "endIndex": 5
        },
        "inheritFromBefore": true
      }
    }]
  }'
```

This inserts 2 rows starting at index 3 (0-based).

### Delete rows or columns

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "deleteDimension": {
        "range": {
          "sheetId": 0,
          "dimension": "ROWS",
          "startIndex": 3,
          "endIndex": 5
        }
      }
    }]
  }'
```

### Hide rows or columns

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "updateDimensionProperties": {
        "range": {
          "sheetId": 0,
          "dimension": "COLUMNS",
          "startIndex": 2,
          "endIndex": 4
        },
        "properties": {
          "hiddenByUser": true
        },
        "fields": "hiddenByUser"
      }
    }]
  }'
```

### Copy a sheet to another spreadsheet

```bash
gws sheets spreadsheets sheets copyTo \
  --params '{"spreadsheetId": "SOURCE_ID", "sheetId": 0}' \
  --json '{"destinationSpreadsheetId": "DEST_ID"}'
```

## Finding the sheetId

The numeric `sheetId` is required for most structural operations. Get it from the spreadsheet metadata:

```bash
gws sheets spreadsheets get \
  --params '{"spreadsheetId": "ID"}' \
  --format json | jq '.sheets[].properties | {title, sheetId}'
```

The first sheet (default) typically has `sheetId: 0`.

## Batch Multiple Structural Changes

Combine multiple requests in one call for efficiency and atomicity:

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [
      {"addSheet": {"properties": {"title": "Summary"}}},
      {"updateDimensionProperties": {
        "range": {"sheetId": 0, "dimension": "COLUMNS", "startIndex": 0, "endIndex": 3},
        "properties": {"pixelSize": 200},
        "fields": "pixelSize"
      }},
      {"updateSheetProperties": {
        "properties": {"sheetId": 0, "gridProperties": {"frozenRowCount": 1}},
        "fields": "gridProperties.frozenRowCount"
      }}
    ]
  }'
```

## Tips

- All indices are **0-based** in the API (row 1 in the UI = index 0).
- `startIndex` is inclusive, `endIndex` is **exclusive** (like Python slices).
- Use `--dry-run` to validate requests before applying.
- Use `"includeSpreadsheetInResponse": true` to get the full spreadsheet state after the update.
- The first sheet always has `sheetId: 0`. Additional sheets get random numeric IDs.

> [!CAUTION]
> These are **write** commands — confirm with the user before executing. Deleting sheets and rows is irreversible.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-sheets](../gws-sheets/SKILL.md) — All Sheets commands
- [gws-sheets-update-values](../gws-sheets-update-values/SKILL.md) — Update cell values
- [gws-sheets-update-format](../gws-sheets-update-format/SKILL.md) — Format cells
- [gws-sheets-update-metadata](../gws-sheets-update-metadata/SKILL.md) — Named ranges, protection, metadata
