---
name: gws-sheets
description: "Google Sheets: Read and write spreadsheets."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws sheets --help"
---

# sheets (v4)

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

```bash
gws sheets <resource> [sub-resource ...] <method> [flags]
```

> **IMPORTANT:** Sheets has deeply nested resources. The full command path is:
> `gws sheets spreadsheets values <method>` — **NOT** `gws sheets values <method>`.
> You must include every resource level (`spreadsheets`, then `values`) as separate words.

### Command Structure

```
gws sheets spreadsheets                                → list/get/create spreadsheets
gws sheets spreadsheets values get    --params '...'   → read a range
gws sheets spreadsheets values update --params '...'   → write a range
gws sheets spreadsheets sheets                         → manage individual sheets
gws sheets +read    --spreadsheet ID --range RANGE      → helper: quick read
gws sheets +append  --spreadsheet ID --values "a,b,c"  → helper: quick append
```

> **Helper commands** (`+read`, `+append`) use their own **flags** (`--spreadsheet`, `--range`, `--values`).
> **Discovery commands** (`spreadsheets values get`, etc.) use `--params` and `--json`.
> Do NOT mix these — never pass `--params` to a helper, and never omit the full resource path for a Discovery command.

## Helper Commands

| Command | Description |
|---------|-------------|
| [`+append`](../gws-sheets-append/SKILL.md) | Append a row to a spreadsheet |
| [`+read`](../gws-sheets-read/SKILL.md) | Read values from a spreadsheet |

## Update Skills

| Skill | Description |
|-------|-------------|
| [`update-values`](../gws-sheets-update-values/SKILL.md) | Update and clear cell values |
| [`update-format`](../gws-sheets-update-format/SKILL.md) | Format cells, merge, conditional formatting |
| [`update-structure`](../gws-sheets-update-structure/SKILL.md) | Add/delete sheets, resize, freeze panes |
| [`update-metadata`](../gws-sheets-update-metadata/SKILL.md) | Named ranges, protection, developer metadata |

## API Resources

### spreadsheets

  - `batchUpdate` — Applies one or more updates to the spreadsheet. Each request is validated before being applied. If any request is not valid then the entire request will fail and nothing will be applied. Some requests have replies to give you some information about how they are applied. The replies will mirror the requests. For example, if you applied 4 updates and the 3rd one had a reply, then the response will have 2 empty replies, the actual reply, and another empty reply, in that order.
  - `create` — Creates a spreadsheet, returning the newly created spreadsheet.
  - `get` — Returns the spreadsheet at the given ID. The caller must specify the spreadsheet ID. By default, data within grids is not returned. You can include grid data in one of 2 ways: * Specify a [field mask](https://developers.google.com/workspace/sheets/api/guides/field-masks) listing your desired fields using the `fields` URL parameter in HTTP * Set the includeGridData URL parameter to true.
  - `getByDataFilter` — Returns the spreadsheet at the given ID. The caller must specify the spreadsheet ID. For more information, see [Read, write, and search metadata](https://developers.google.com/workspace/sheets/api/guides/metadata). This method differs from GetSpreadsheet in that it allows selecting which subsets of spreadsheet data to return by specifying a dataFilters parameter. Multiple DataFilters can be specified.
  - `developerMetadata` — Operations on the 'developerMetadata' resource
  - `sheets` — Operations on the 'sheets' resource
  - `values` — Operations on the 'values' resource

## Discovering Commands

Before calling any API method, inspect it:

```bash
# Browse resources and methods
gws sheets --help

# Inspect a method's required params, types, and defaults
gws schema sheets.<resource>.<method>
```

Use `gws schema` output to build your `--params` and `--json` flags.

