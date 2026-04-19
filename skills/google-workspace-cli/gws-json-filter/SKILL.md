---
name: GWS JSON Filter
description: Filter large GWS CLI JSON responses (calendar events, emails, etc.) by specific fields like title, attendee, date. Prevents LLM context overflow by extracting only matching items programmatically.
---

# GWS JSON Filter

## When to Use

Use this skill whenever a `gws` CLI command returns a large JSON response and you need to find specific items. **Do NOT visually scan large JSON output** — use `execute_code` to filter programmatically.

Common scenarios:
- Find calendar events by title/summary (e.g. "find all events named TrailblazerDX")
- Find calendar events by attendee email
- Find calendar events within a date range
- Find emails by subject or sender
- Any `gws` response with more than ~10 items

## ⚠️ Two-Step Pattern (MUST follow)

`python3 -c` is blocked in bash mode. You **MUST** use two separate `execute_code` calls. Both calls share the same working directory (`workspace/`), so files persist between calls.

### Step 1 — Fetch and save to file (`execute_code(language="bash")`)

Use shell redirect `>` to save gws output to a file. Do **NOT** use the gws `-o` flag — it may fail silently.

**⚠️ NEVER use `set -e` in the bash script.** Always start with `set +e` to prevent the script from aborting on non-zero exit codes. The gws command may return non-zero even on partial success, and `set -e` will kill the script before the status check runs.

```bash
set +e
gws calendar events list --params '{"calendarId":"primary","q":"keyword"}' > _events_raw.json 2>&1
echo "OK: saved to _events_raw.json"
```

**Check the output!** If Step 1 shows a gws error, do NOT proceed to Step 2 — fix the gws command first.

The `q` parameter does a broad text search (matches summary, description, location). Use it to pre-filter when possible.

For paginated results, add `--page-all`:
```bash
set +e
gws calendar events list --params '{"calendarId":"primary"}' --page-all > _events_raw.json 2>&1
echo "OK"
```

**Important:** `>` redirects stdout to the file. The gws JSON output goes into the file instead of printing to the terminal, keeping your context clean.

### Step 2 — Filter with Python (`execute_code(language="python")`)

**Only proceed if Step 1 printed "OK".**

All examples below automatically **skip cancelled/deleted events** by filtering on the `status` field. Google Calendar events have `status` = `confirmed`, `tentative`, or `cancelled`. Only `confirmed` and `tentative` are active events.

#### Common helper — parse JSON file and filter out inactive events:
Every filter script should start with this pattern:
```python
import json, os, sys

filepath = '_events_raw.json'
if not os.path.exists(filepath):
    print(f"ERROR: {filepath} not found. Step 1 (gws command) likely failed.")
    sys.exit(1)

with open(filepath) as f:
    content = f.read().strip()

if content.startswith('{'):
    raw_items = json.loads(content).get('items', [])
else:
    raw_items = []
    for line in content.splitlines():
        line = line.strip()
        if line:
            raw_items.extend(json.loads(line).get('items', []))

INACTIVE_STATUSES = {'cancelled', 'deleted'}
items = [e for e in raw_items if e.get('status', '').lower() not in INACTIVE_STATUSES]
print(f"Loaded {len(raw_items)} total event(s), {len(raw_items) - len(items)} cancelled/deleted, {len(items)} active.")
```

#### Filter by title (summary):
```python
import json, os, sys

filepath = '_events_raw.json'
if not os.path.exists(filepath):
    print(f"ERROR: {filepath} not found. Step 1 (gws command) likely failed.")
    sys.exit(1)

with open(filepath) as f:
    content = f.read().strip()

if content.startswith('{'):
    raw_items = json.loads(content).get('items', [])
else:
    raw_items = []
    for line in content.splitlines():
        line = line.strip()
        if line:
            raw_items.extend(json.loads(line).get('items', []))

INACTIVE_STATUSES = {'cancelled', 'deleted'}
items = [e for e in raw_items if e.get('status', '').lower() not in INACTIVE_STATUSES]
print(f"Loaded {len(raw_items)} total, {len(raw_items) - len(items)} inactive, {len(items)} active.")

keyword = "TrailblazerDX"
matches = [e for e in items if keyword.lower() in e.get('summary', '').lower()]

for e in matches:
    print(f"ID: {e['id']}")
    print(f"  Title: {e.get('summary','')}")
    print(f"  Status: {e.get('status','')}")
    print(f"  Start: {e.get('start',{}).get('dateTime','')}")
    print(f"  Attendees: {[a.get('email','') for a in e.get('attendees',[])]}")
    print()

print(f"Found {len(matches)} matching active event(s).")

os.remove(filepath)
```

#### Filter by attendee email:
```python
import json, os, sys

filepath = '_events_raw.json'
if not os.path.exists(filepath):
    print(f"ERROR: {filepath} not found. Step 1 (gws command) likely failed.")
    sys.exit(1)

with open(filepath) as f:
    content = f.read().strip()

if content.startswith('{'):
    raw_items = json.loads(content).get('items', [])
else:
    raw_items = []
    for line in content.splitlines():
        line = line.strip()
        if line:
            raw_items.extend(json.loads(line).get('items', []))

INACTIVE_STATUSES = {'cancelled', 'deleted'}
items = [e for e in raw_items if e.get('status', '').lower() not in INACTIVE_STATUSES]
print(f"Loaded {len(raw_items)} total, {len(raw_items) - len(items)} inactive, {len(items)} active.")

target_email = 'wei.zeng@example.com'
matches = [
    e for e in items
    if any(a.get('email','').lower() == target_email.lower() for a in e.get('attendees', []))
]

for e in matches:
    print(f"ID: {e['id']}  Title: {e.get('summary','')}  Status: {e.get('status','')}")
print(f"Found {len(matches)} active event(s) with attendee {target_email}")

os.remove(filepath)
```

#### Filter by date range:
```python
import json, os, sys
from datetime import datetime

filepath = '_events_raw.json'
if not os.path.exists(filepath):
    print(f"ERROR: {filepath} not found. Step 1 (gws command) likely failed.")
    sys.exit(1)

with open(filepath) as f:
    content = f.read().strip()

if content.startswith('{'):
    raw_items = json.loads(content).get('items', [])
else:
    raw_items = []
    for line in content.splitlines():
        line = line.strip()
        if line:
            raw_items.extend(json.loads(line).get('items', []))

INACTIVE_STATUSES = {'cancelled', 'deleted'}
items = [e for e in raw_items if e.get('status', '').lower() not in INACTIVE_STATUSES]
print(f"Loaded {len(raw_items)} total, {len(raw_items) - len(items)} inactive, {len(items)} active.")

after = datetime(2026, 4, 1)
before = datetime(2026, 4, 30)

matches = []
for e in items:
    start_str = e.get('start', {}).get('dateTime', e.get('start', {}).get('date', ''))
    if start_str:
        dt = datetime.fromisoformat(start_str.replace('Z', '+00:00'))
        if after <= dt.replace(tzinfo=None) <= before:
            matches.append(e)

for e in matches:
    print(f"ID: {e['id']}  Title: {e.get('summary','')}  Status: {e.get('status','')}  Start: {e.get('start',{}).get('dateTime','')}")
print(f"Found {len(matches)} active event(s) in date range.")

os.remove(filepath)
```

## Using Filtered Results

After getting filtered event IDs, use them in subsequent `execute_code(language="bash")` calls:

### Delete matching events:
```bash
gws calendar events delete --params '{"calendarId":"primary","eventId":"<EVENT_ID>"}'
```

### Update matching events:
```bash
gws calendar events patch --params '{"calendarId":"primary","eventId":"<EVENT_ID>","requestBody":{"summary":"New Title"}}'
```

## Key Rules

- **NEVER use `set -e` in bash scripts** — always start with `set +e`. `set -e` will abort the script if gws returns non-zero, preventing file write and status output
- **Two steps: bash then python** — `python3 -c` is blocked in bash, so always use two `execute_code` calls
- **Verify Step 1 succeeded** before running Step 2 — check for "OK" output
- **Always check file existence** in Python with `os.path.exists()` before opening
- **Handle both JSON and NDJSON** — `--page-all` outputs one JSON per line, non-paginated outputs a single JSON object
- **Always save to file** using shell redirect (`> _events_raw.json`) — do NOT use gws `-o` flag, it may fail silently
- **Always filter out inactive events** — skip events with `status` = `cancelled` or `deleted` before applying any other filter
- **Use case-insensitive matching** — `.lower()` on both sides
- **Clean up temp files** — `os.remove(filepath)` at the end of Python step
