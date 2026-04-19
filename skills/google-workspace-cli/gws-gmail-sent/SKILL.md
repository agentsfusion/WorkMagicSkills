---
name: gws-gmail-sent
description: "Gmail: View sent email and reply content. Use when checking what was sent, reviewing past replies, viewing sent message bodies, or inspecting conversation threads."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws gmail +triage --help"
---

# gmail — view sent & replies

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

View sent emails, reply content, and conversation threads.

## Commands

### List sent messages (quick summary)

Use `+triage` with a sent-mail query to see a table of recent sent messages:

```bash
gws gmail +triage --query "in:sent"
gws gmail +triage --query "in:sent" --max 10
gws gmail +triage --query "in:sent" --format json
```

### List sent messages via Discovery

Fuller control over fields and pagination:

```bash
gws gmail users messages list \
  --params '{"q": "in:sent", "maxResults": 10}'
```

### List sent replies only

Narrow to messages that are replies (have `Re:` in subject or are part of a thread with 2+ messages):

```bash
gws gmail +triage --query "in:sent subject:Re:"
gws gmail users messages list \
  --params '{"q": "in:sent subject:Re:", "maxResults": 10}'
```

### Read a specific sent message

Use `+read` with the message ID from a listing:

```bash
gws gmail +read --id MESSAGE_ID
gws gmail +read --id MESSAGE_ID --headers
gws gmail +read --id MESSAGE_ID --format json
```

### Read a specific sent message via Discovery

Get full raw payload with all headers and body parts:

```bash
gws gmail users messages get \
  --params '{"id": "MESSAGE_ID", "format": "full"}'
```

### View a full conversation thread

See all messages (original + all replies) in a thread:

```bash
gws gmail users threads get \
  --params '{"id": "THREAD_ID", "format": "full"}'
```

List threads containing sent replies:

```bash
gws gmail users threads list \
  --params '{"q": "in:sent", "maxResults": 10}'
```

### Get the thread ID for a message

```bash
gws gmail users messages get \
  --params '{"id": "MESSAGE_ID", "format": "minimal"}' \
  --format json | jq '.threadId'
```

## Gmail Search Queries

The `q` parameter in `users.messages list` and `users.threads list` accepts Gmail search operators:

| Query | What it finds |
|-------|--------------|
| `in:sent` | All sent mail |
| `in:sent subject:Re:` | Sent replies only |
| `in:sent to:user@example.com` | Sent to a specific person |
| `in:sent after:2026/01/01` | Sent after a date |
| `in:sent before:2026/04/01` | Sent before a date |
| `in:sent has:attachment` | Sent mail with attachments |
| `in:sent label:Starred` | Starred sent mail |
| `is:sent from:me` | Alternative: sent by you (includes auto-replies) |
| `rfc822msgid:<id>` | Find by Message-ID header (exact match) |
| `threadid:<id>` | Find messages in a specific thread |

Combine operators: `in:sent to:alice@example.com after:2026/03/01 subject:Re:`

## Common Patterns

### Review today's sent replies

```bash
gws gmail +triage --query "in:sent after:$(date +%Y/%m/%d)"
```

### Read the latest sent message in a thread

```bash
# Step 1: List sent messages in a thread
gws gmail users messages list \
  --params '{"q": "in:sent rfc822msgid:<original-message-id>"}' \
  --format json | jq '.messages[0].id'

# Step 2: Read it
gws gmail +read --id <MESSAGE_ID> --headers
```

### View a complete back-and-forth conversation

```bash
# Step 1: Find the thread
gws gmail users messages list \
  --params '{"q": "in:sent subject:Project Update", "maxResults": 1}' \
  --format json | jq '.messages[0].threadId'

# Step 2: Get the full thread
gws gmail users threads get \
  --params '{"id": "THREAD_ID", "format": "full"}' \
  --format json | jq '.messages[] | {id, snippet, payload: {headers: [.payload.headers[] | select(.name == "From" or .name == "To" or .name == "Subject" or .name == "Date")]}}'
```

### Check if a reply was sent to a specific person

```bash
gws gmail +triage --query "in:sent to:alice@example.com" --max 5
```

### Export sent replies as structured data

```bash
gws gmail users messages list \
  --params '{"q": "in:sent subject:Re:", "maxResults": 50}' \
  --page-all --format json | jq '{id, threadId, snippet}'
```

## Message Formats

The `format` parameter in `users.messages get` controls the level of detail:

| Format | Content | Use When |
|--------|---------|----------|
| `minimal` | Headers (From, To, Subject) + labels only | Quick preview, get threadId |
| `metadata` | All headers, no body | Check recipients, dates, threading |
| `full` | Headers + body parts (parsed MIME) | Read the full message body |
| `raw` | Full RFC 2822 base64-encoded | Inspect raw headers, DKIM, etc. |

## Tips

- Read-only — never modifies your mailbox.
- `+triage` gives a quick table view; `+read` gives the full body.
- Use `users.threads get` to see a complete conversation in one call.
- For paginated results, use `--page-all` to stream all results as NDJSON.
- Gmail search queries support the same operators as the Gmail web search bar.
- Use `--dry-run` with write commands but these are all read-only.
- After sending with `+reply` or `+send`, use these commands to verify what was sent.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-gmail](../gws-gmail/SKILL.md) — All Gmail commands
- [gws-gmail-read](../gws-gmail-read/SKILL.md) — Read a single message
- [gws-gmail-triage](../gws-gmail-triage/SKILL.md) — Inbox summary with custom queries
- [gws-gmail-reply](../gws-gmail-reply/SKILL.md) — Reply to a message
- [gws-gmail-send](../gws-gmail-send/SKILL.md) — Send a new email
