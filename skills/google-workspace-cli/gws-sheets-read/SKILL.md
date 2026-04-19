---
name: gws-sheets-read
description: "Google Sheets: Read values from a spreadsheet."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws sheets +read --help"
---

# sheets +read

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

Read values from a spreadsheet.

> **IMPORTANT:** `+read` is a **helper command** — it uses `--spreadsheet` and `--range` **flags**, NOT `--params`.
> Discovery API commands use the full nested path with `--params`.

## Usage

### Helper command (recommended for most reads)

```bash
gws sheets +read --spreadsheet <ID> --range <RANGE>
```

### Discovery API command (for advanced options)

```bash
gws sheets spreadsheets values get \
  --params '{"spreadsheetId": "SPREADSHEET_ID", "range": "Sheet1!A1:D10"}'
```

## Flags (Helper: `+read`)

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--spreadsheet` | ✓ | — | Spreadsheet ID |
| `--range` | ✓ | — | Range to read (e.g. "Sheet1!A1:B2") |

> **Do NOT use `--params` with `+read`.** The `--params` flag is for Discovery commands only.

## Examples

```bash
# Helper: quick read (recommended)
gws sheets +read --spreadsheet ID --range "Sheet1!A1:D10"
gws sheets +read --spreadsheet ID --range Sheet1

# Discovery: read with full API control
gws sheets spreadsheets values get \
  --params '{"spreadsheetId": "ID", "range": "Sheet1!A1:D10"}'

# Discovery: read multiple ranges at once
gws sheets spreadsheets values batchGet \
  --params '{"spreadsheetId": "ID", "ranges": ["Sheet1!A1:B10", "Sheet2!C1:D5"]}'
```

## Common Mistakes

| ❌ Wrong | ✅ Correct | Why |
|---------|-----------|-----|
| `gws sheets values get --params '...'` | `gws sheets spreadsheets values get --params '...'` | Missing `spreadsheets` resource |
| `gws sheets read --params '...'` | `gws sheets +read --spreadsheet ID --range RANGE` | `read` doesn't exist; use `+read` |
| `gws sheets +read --params '...'` | `gws sheets +read --spreadsheet ID --range RANGE` | `+read` uses flags, not `--params` |

## Tips

- Read-only — never modifies the spreadsheet.
- For advanced options (batch get, data filters), use the Discovery command `spreadsheets values get` or `spreadsheets values batchGet`.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-sheets](../gws-sheets/SKILL.md) — All read and write spreadsheets commands
