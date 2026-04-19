---
name: gws-sheets-update-format
description: "Google Sheets: Format cells, merge cells, add conditional formatting, and apply visual styles."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws sheets spreadsheets batchUpdate --help"
---

# sheets — update format

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

Apply visual formatting to cells: text styles, backgrounds, borders, number formats, merges, and conditional formatting rules. All formatting changes use the `spreadsheets.batchUpdate` endpoint.

## Core Command

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "SPREADSHEET_ID"}' \
  --json '{"requests": [ ... ]}'
```

## Operations

### Format cells (text, background, alignment)

Use `repeatCell` to apply formatting to a range. The `CellFormat` object controls all visual properties.

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "repeatCell": {
        "range": {
          "sheetId": 0,
          "startRowIndex": 0,
          "endRowIndex": 1,
          "startColumnIndex": 0,
          "endColumnIndex": 5
        },
        "cell": {
          "userEnteredFormat": {
            "textFormat": {
              "bold": true,
              "fontSize": 12,
              "foregroundColor": {"red": 1, "green": 1, "blue": 1}
            },
            "backgroundColor": {"red": 0.2, "green": 0.4, "blue": 0.8},
            "horizontalAlignment": "CENTER",
            "verticalAlignment": "MIDDLE"
          }
        },
        "fields": "userEnteredFormat(textFormat,backgroundColor,horizontalAlignment,verticalAlignment)"
      }
    }]
  }'
```

### Number format

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "repeatCell": {
        "range": {
          "sheetId": 0,
          "startRowIndex": 1,
          "endRowIndex": 10,
          "startColumnIndex": 1,
          "endColumnIndex": 2
        },
        "cell": {
          "userEnteredFormat": {
            "numberFormat": {
              "type": "CURRENCY",
              "pattern": "$#,##0.00"
            }
          }
        },
        "fields": "userEnteredFormat.numberFormat"
      }
    }]
  }'
```

Common number format types: `TEXT`, `NUMBER`, `PERCENT`, `CURRENCY`, `DATE`, `TIME`, `DATE_TIME`, `SCIENTIFIC`.

### Borders

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "updateBorders": {
        "range": {
          "sheetId": 0,
          "startRowIndex": 0,
          "endRowIndex": 10,
          "startColumnIndex": 0,
          "endColumnIndex": 5
        },
        "top": {"style": "SOLID_THIN", "color": {"red": 0, "green": 0, "blue": 0}},
        "bottom": {"style": "SOLID_THIN", "color": {"red": 0, "green": 0, "blue": 0}},
        "left": {"style": "SOLID_THIN", "color": {"red": 0, "green": 0, "blue": 0}},
        "right": {"style": "SOLID_THIN", "color": {"red": 0, "green": 0, "blue": 0}},
        "innerHorizontal": {"style": "SOLID_THIN", "color": {"red": 0.7, "green": 0.7, "blue": 0.7}},
        "innerVertical": {"style": "SOLID_THIN", "color": {"red": 0.7, "green": 0.7, "blue": 0.7}}
      }
    }]
  }'
```

Border styles: `SOLID`, `SOLID_THIN`, `SOLID_MEDIUM`, `SOLID_THICK`, `DOTTED`, `DASHED`, `DOUBLE`.

### Merge cells

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "mergeCells": {
        "range": {
          "sheetId": 0,
          "startRowIndex": 0,
          "endRowIndex": 2,
          "startColumnIndex": 0,
          "endColumnIndex": 4
        },
        "mergeType": "MERGE_ALL"
      }
    }]
  }'
```

Merge types: `MERGE_ALL` (default) or `MERGE_ROWS` (merge each row independently).

### Unmerge cells

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "unmergeCells": {
        "range": {
          "sheetId": 0,
          "startRowIndex": 0,
          "endRowIndex": 2,
          "startColumnIndex": 0,
          "endColumnIndex": 4
        }
      }
    }]
  }'
```

### Conditional formatting — color scale

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "addConditionalFormatRule": {
        "rule": {
          "ranges": [{
            "sheetId": 0,
            "startRowIndex": 1,
            "endRowIndex": 10,
            "startColumnIndex": 1,
            "endColumnIndex": 2
          }],
          "gradientRule": {
            "minpoint": {"color": {"red": 1, "green": 0, "blue": 0}, "type": "MIN"},
            "maxpoint": {"color": {"red": 0, "green": 1, "blue": 0}, "type": "MAX"}
          }
        },
        "index": 0
      }
    }]
  }'
```

### Conditional formatting — cell value rule

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "addConditionalFormatRule": {
        "rule": {
          "ranges": [{
            "sheetId": 0,
            "startRowIndex": 1,
            "endRowIndex": 10,
            "startColumnIndex": 2,
            "endColumnIndex": 3
          }],
          "booleanRule": {
            "condition": {
              "type": "TEXT_EQ",
              "values": [{"userEnteredValue": "Complete"}]
            },
            "format": {
              "textFormat": {"foregroundColor": {"red": 0, "green": 0.6, "blue": 0}},
              "backgroundColor": {"red": 0.9, "green": 1, "blue": 0.9}
            }
          }
        },
        "index": 0
      }
    }]
  }'
```

### Delete conditional formatting rule

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "deleteConditionalFormatRule": {
        "sheetId": 0,
        "index": 0
      }
    }]
  }'
```

### Text rotation

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [{
      "repeatCell": {
        "range": {
          "sheetId": 0,
          "startRowIndex": 0,
          "endRowIndex": 1,
          "startColumnIndex": 0,
          "endColumnIndex": 5
        },
        "cell": {
          "userEnteredFormat": {
            "textFormat": {"bold": true},
            "textRotation": {"angle": 45}
          }
        },
        "fields": "userEnteredFormat(textFormat.bold,textRotation)"
      }
    }]
  }'
```

## Color Reference

Colors use floating-point RGB values (0.0–1.0):

| Color | RGB |
|-------|-----|
| Black | `{"red": 0, "green": 0, "blue": 0}` |
| White | `{"red": 1, "green": 1, "blue": 1}` |
| Red | `{"red": 1, "green": 0, "blue": 0}` |
| Green | `{"red": 0, "green": 1, "blue": 0}` |
| Blue | `{"red": 0, "green": 0, "blue": 1}` |
| Yellow | `{"red": 1, "green": 1, "blue": 0}` |
| Gray | `{"red": 0.5, "green": 0.5, "blue": 0.5}` |
| Light gray | `{"red": 0.9, "green": 0.9, "blue": 0.9}` |

## Batch Multiple Formatting Changes

```bash
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "ID"}' \
  --json '{
    "requests": [
      {
        "repeatCell": {
          "range": {"sheetId": 0, "startRowIndex": 0, "endRowIndex": 1, "startColumnIndex": 0, "endColumnIndex": 5},
          "cell": {"userEnteredFormat": {"textFormat": {"bold": true}, "backgroundColor": {"red": 0.2, "green": 0.4, "blue": 0.8}}},
          "fields": "userEnteredFormat(textFormat,backgroundColor)"
        }
      },
      {
        "updateBorders": {
          "range": {"sheetId": 0, "startRowIndex": 0, "endRowIndex": 10, "startColumnIndex": 0, "endColumnIndex": 5},
          "top": {"style": "SOLID_MEDIUM"},
          "bottom": {"style": "SOLID_MEDIUM"},
          "innerHorizontal": {"style": "SOLID_THIN"}
        }
      },
      {
        "mergeCells": {
          "range": {"sheetId": 0, "startRowIndex": 0, "endRowIndex": 1, "startColumnIndex": 0, "endColumnIndex": 5},
          "mergeType": "MERGE_ALL"
        }
      }
    ]
  }'
```

## Tips

- All indices are **0-based** (row 1 in UI = `startRowIndex: 0`).
- `startIndex` is inclusive, `endIndex` is **exclusive**.
- Use `--dry-run` to validate before applying.
- The `fields` parameter in `repeatCell` uses a field mask — list only the properties you want to change.
- Formatting changes are **non-destructive** — they don't alter cell values.
- For finding the `sheetId`, see [gws-sheets-update-structure](../gws-sheets-update-structure/SKILL.md#finding-the-sheetid).

> [!CAUTION]
> These are **write** commands — confirm with the user before executing.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-sheets](../gws-sheets/SKILL.md) — All Sheets commands
- [gws-sheets-update-values](../gws-sheets-update-values/SKILL.md) — Update cell values
- [gws-sheets-update-structure](../gws-sheets-update-structure/SKILL.md) — Add/delete sheets, resize
- [gws-sheets-update-metadata](../gws-sheets-update-metadata/SKILL.md) — Named ranges, protection, metadata
