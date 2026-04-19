---
name: gws-sheets-update-metadata
description: "Google Sheets: Add named ranges, protect ranges, and manage developer metadata."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws sheets spreadsheets batchUpdate --help"
---

# sheets — update metadata

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

Manage spreadsheet metadata: named ranges, protected ranges (lock cells from editing), and developer metadata for programmatic tagging. All metadata operations use the `spreadsheets.batchUpdate` endpoint or dedicated resource endpoints.

## Core Command

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "SPREADSHEET_ID"}' \
  --json '{"requests": [ ... ]}'
```

## Named Ranges

### Add a named range

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "addNamedRange": {
        "namedRange": {
          "name": "SalesData",
          "range": {
            "sheetId": 0,
            "startRowIndex": 0,
            "endRowIndex": 100,
            "startColumnIndex": 0,
            "endColumnIndex": 5
          }
        }
      }
    }]
  }'
```

Response includes `addNamedRange.namedRange.namedRangeId`.

### Delete a named range

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "deleteNamedRange": {
        "namedRangeId": "NAMED_RANGE_ID"
      }
    }]
  }'
```

### Update a named range

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "updateNamedRange": {
        "namedRange": {
          "namedRangeId": "NAMED_RANGE_ID",
          "name": "UpdatedName",
          "range": {
            "sheetId": 0,
            "startRowIndex": 0,
            "endRowIndex": 200,
            "startColumnIndex": 0,
            "endColumnIndex": 5
          }
        },
        "fields": "name,range"
      }
    }]
  }'
```

## Protected Ranges

### Protect a range (prevent editing)

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "addProtectedRange": {
        "protectedRange": {
          "range": {
            "sheetId": 0,
            "startRowIndex": 0,
            "endRowIndex": 1,
            "startColumnIndex": 0,
            "endColumnIndex": 5
          },
          "description": "Header row — do not edit",
          "warningOnly": false
        }
      }
    }]
  }'
```

Set `"warningOnly": true` to show a warning instead of blocking edits.

### Protect an entire sheet

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "addProtectedRange": {
        "protectedRange": {
          "sheetId": 0,
          "description": "Read-only sheet",
          "warningOnly": false
        }
      }
    }]
  }'
```

### Delete a protected range

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "deleteProtectedRange": {
        "protectedRangeId": 12345
      }
    }]
  }'
```

## Developer Metadata

Developer metadata is invisible to users — it's for programmatic tagging of spreadsheets, sheets, rows, columns, or ranges.

### Add developer metadata

```bash
gws sheets spreadsheets developerMetadata create \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "developerMetadata": {
      "metadataKey": "data-source",
      "metadataValue": "sales-api-v2",
      "location": {
        "spreadsheet": true
      },
      "visibility": "DOCUMENT"
    }
  }'
```

### Search developer metadata

```bash
gws sheets spreadsheets developerMetadata search \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "dataFilters": [
      {"developerMetadataLookup": {"metadataKey": "data-source"}}
    ]
  }'
```

### Update developer metadata

```bash
gws sheets spreadsheets developerMetadata update \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "dataFilters": [
      {"developerMetadataLookup": {"metadataKey": "data-source"}}
    ],
    "developerMetadata": {
      "metadataKey": "data-source",
      "metadataValue": "sales-api-v3",
      "visibility": "DOCUMENT"
    },
    "fields": "metadataValue"
  }'
```

### Delete developer metadata

```bash
gws sheets spreadsheets developerMetadata delete \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "dataFilters": [
      {"developerMetadataLookup": {"metadataKey": "data-source"}}
    ]
  }'
```

## Data Validation

### Add dropdown validation to a range

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "setDataValidation": {
        "range": {
          "sheetId": 0,
          "startRowIndex": 1,
          "endRowIndex": 100,
          "startColumnIndex": 3,
          "endColumnIndex": 4
        },
        "rule": {
          "condition": {
            "type": "ONE_OF_LIST",
            "values": [
              {"userEnteredValue": "Pending"},
              {"userEnteredValue": "In Progress"},
              {"userEnteredValue": "Complete"}
            ]
          },
          "showCustomUi": true,
          "strict": true
        }
      }
    }]
  }'
```

### Remove data validation

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "setDataValidation": {
        "range": {
          "sheetId": 0,
          "startRowIndex": 1,
          "endRowIndex": 100,
          "startColumnIndex": 3,
          "endColumnIndex": 4
        }
      }
    }]
  }'
```

Omit `rule` entirely to clear validation from the range.

## Finding IDs

### Named range IDs

```bash
gws sheets spreadsheets get \
  --params '{"spreadsheetId": "ID"}' \
  --format json | jq '.namedRanges[] | {name, namedRangeId}'
```

### Protected range IDs

```bash
gws sheets spreadsheets get \
  --params '{"spreadsheetId": "ID"}' \
  --format json | jq '.sheets[].protectedRanges[] | {protectedRangeId, description}'
```

## Tips

- Named range names must be unique within a spreadsheet.
- Protected range IDs are numeric and auto-assigned.
- Developer metadata visibility: `DOCUMENT` (visible via API) or `PROJECT` (visible only to the project that created it).
- Use `--dry-run` to validate requests before applying.
- All indices are **0-based**; `startIndex` is inclusive, `endIndex` is exclusive.

> [!CAUTION]
> These are **write** commands — confirm with the user before executing. Protection changes can lock users out of editing.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-sheets](../gws-sheets/SKILL.md) — All Sheets commands
- [gws-sheets-update-values](../gws-sheets-update-values/SKILL.md) — Update cell values
- [gws-sheets-update-structure](../gws-sheets-update-structure/SKILL.md) — Add/delete sheets, resize
- [gws-sheets-update-format](../gws-sheets-update-format/SKILL.md) — Format cells
