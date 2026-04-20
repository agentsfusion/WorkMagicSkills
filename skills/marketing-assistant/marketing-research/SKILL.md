---
name: marketing-research
description: "Market intelligence research via web search: find conferences, competitor news, industry trends, company updates. Use when: researching market opportunities before outreach, finding industry events, analyzing competitors, gathering company intelligence. Triggers: market research, 市场调研, conference, 竞品, 行业动态, 搜索信息, industry news, competitor analysis."
triggers:
  - market research
  - 市场调研
  - conference
  - 竞品
  - 行业动态
  - 搜索信息
---

# marketing-research

> Market intelligence via web search: conferences, competitors, industry trends, company news.

## When to Use

- Finding industry conferences, trade shows, or networking events
- Researching a company before reaching out (news, products, leadership changes)
- Comparing competitor products, pricing, or market positioning
- Gathering industry trends or market data for outreach personalization
- Any "look up X" or "find information about Y" request in a marketing context

## Research Modes

### Mode 1: Conference/Event Search

Find relevant industry events.

**Extract per event:**
- Event name
- Dates
- Location (city + country)
- Registration URL
- Exhibitor list (if available)
- Key contacts or speakers
- Relevance to target customer

**Sample queries:**
- `[industry] conferences 2026`
- `[industry] trade shows [region]`
- `[company] events sponsorship`

### Mode 2: Company Intelligence

Gather news and updates about target companies.

**Extract per company:**
- Recent announcements (product launches, partnerships)
- Funding rounds or financial news
- Leadership changes
- Office openings or expansions
- Press mentions

**Sample queries:**
- `[company] news 2026`
- `[company] product announcement`
- `[company] funding round`

### Mode 3: Competitor Analysis

Compare products and positioning.

**Extract per competitor:**
- Product features
- Pricing tiers
- Target market / positioning
- Recent changes or launches
- Strengths and gaps

**Sample queries:**
- `[product type] competitors comparison`
- `[company] vs alternatives`
- `[product category] pricing 2026`

### Mode 4: General Research

Free-form search on any market topic. Use when the request doesn't fit the modes above. Apply the same search strategy and output format.

## Search Strategy

Follow these steps in order.

### Step 1: Clarify Scope

Before searching, confirm with the user:
- What topic or company?
- Which industry or region?
- How recent should the information be?
- How many results are enough?

If the user's request is already specific, skip to Step 2.

### Step 2: Search

Use one or both of these tools:

- **`google_search`** — Good for broad queries, supports `urls` parameter for direct page analysis. Always set `thinking=true`.
- **`websearch_web_search_exa`** — Good for semantic/descriptive queries. Write queries as natural language descriptions, not keywords.

For each search, use targeted queries. Prefer specific over broad:
- Bad: `marketing conference`
- Good: `B2B SaaS marketing conferences Europe 2026`

Run multiple queries when needed. For a company intelligence task, search for news, products, and leadership separately.

### Step 3: Extract Detail

For promising results, use **`web-reader_webReader`** to extract full article content. This gives cleaner, more detailed information than search snippets.

Use this when:
- A search result looks highly relevant
- You need specifics (dates, prices, names) not in the snippet
- The user asked for detailed information

### Step 4: Synthesize

Combine findings into the structured report format below. Every finding must include a source URL.

### Step 5: Present

Show the report to the user. Ask if they want deeper research on any finding, or if they're ready to use the results for outreach.

## Output Format

Use this template for all research results:

```markdown
## Market Research Report
### Topic: [topic] | Date: [YYYY-MM-DD]

#### Key Findings
1. [Finding] — [Source URL]
2. [Finding] — [Source URL]
3. [Finding] — [Source URL]

#### Relevant Events/Contacts
- [Event name] — [Date] — [Location] — [URL]
- [Contact name] — [Title] — [Company] — [Source URL]

#### Summary
[2-3 sentences capturing the most actionable insights. Written so it can be pasted into an email or used as talking points.]
```

**Rules for the report:**
- Every finding gets a source URL. No exceptions.
- The Summary section is the most important part. Write it so someone could use it in an email without editing.
- Remove duplicate findings. If two sources report the same news, pick the more authoritative source.
- Order findings by relevance, not by when you found them.

## Integration with marketing-outreach

Research output lives in conversation context. When the user moves to outreach, the `marketing-outreach` skill reads this context to personalize emails.

**Flow:**
1. User runs research (this skill)
2. User reviews report
3. User asks to send email (triggers `marketing-outreach`)
4. Outreach skill uses research findings to compose personalized email

No data is written to Google Sheet. Research is ephemeral, consumed as context.

## Examples

### Example 1: Conference Search

**User says:** "Find upcoming e-commerce conferences in Asia"

**Search queries:**
- `e-commerce conferences Asia 2026`
- `retail tech summit Southeast Asia 2026`

**Expected output:**
```markdown
## Market Research Report
### Topic: E-commerce conferences in Asia | Date: 2026-04-20

#### Key Findings
1. Retail Asia Expo 2026 scheduled for June 15-17 in Singapore — https://example.com/retail-asia
2. E-commerce Summit Jakarta returns in August 2026 — https://example.com/ecs-jakarta
3. Cross-border commerce track added to TechInAsia conference — https://example.com/techinasia

#### Relevant Events/Contacts
- Retail Asia Expo 2026 — June 15-17 — Singapore — https://example.com/retail-asia
- E-commerce Summit Jakarta — Aug 8-10 — Jakarta — https://example.com/ecs-jakarta

#### Summary
Three major e-commerce events in Asia this year. Retail Asia Expo in Singapore (June) is the largest with 5000+ attendees and a dedicated cross-border commerce track. E-commerce Summit Jakarta in August focuses on Southeast Asian market entry.
```

### Example 2: Company Intelligence

**User says:** "What's new with Shopify lately?"

**Search queries:**
- `Shopify news 2026`
- `Shopify product announcement 2026`
- `Shopify leadership changes 2026`

**Expected output:**
```markdown
## Market Research Report
### Topic: Shopify recent updates | Date: 2026-04-20

#### Key Findings
1. Shopify launched AI-powered inventory forecasting in March 2026 — https://example.com/shopify-ai
2. Shopify expanded Shopify Payments to 5 new markets in Southeast Asia — https://example.com/shopify-payments
3. Q1 2026 earnings showed 22% YoY GMV growth — https://example.com/shopify-earnings

#### Relevant Events/Contacts
- Shopify Unite 2026 — Sep 10-12 — Toronto — https://example.com/shopify-unite

#### Summary
Shopify is investing heavily in AI tooling and Southeast Asian expansion. Their new inventory forecasting feature and payments expansion into 5 new markets signal aggressive growth in the region. Good angle for outreach to e-commerce prospects in SEA.
```

### Example 3: Competitor Analysis

**User says:** "Compare HubSpot vs Salesforce for mid-market CRM"

**Search queries:**
- `HubSpot vs Salesforce mid-market CRM comparison 2026`
- `HubSpot pricing 2026`
- `Salesforce pricing mid-market 2026`

**Expected output:**
```markdown
## Market Research Report
### Topic: HubSpot vs Salesforce mid-market CRM | Date: 2026-04-20

#### Key Findings
1. HubSpot offers free CRM tier, Salesforce starts at $25/user/month — https://example.com/crm-pricing
2. Salesforce stronger in enterprise integrations, HubSpot easier to adopt — https://example.com/crm-compare
3. HubSpot added AI email drafting in Feb 2026, Salesforce rolled Einstein GPT to all tiers — https://example.com/crm-ai

#### Relevant Events/Contacts
(No events found for this topic)

#### Summary
For mid-market, HubSpot wins on ease of use and cost (free tier available). Salesforce wins on integration depth and enterprise readiness. Both now offer AI features at comparable tiers. Outreach angle: target mid-market companies using Salesforce who might benefit from HubSpot's simpler onboarding.
```

## Tips

- **Recency matters.** Add the year to search queries. "Shopify news" returns old results; "Shopify news 2026" is better.
- **Go deep on the top 3.** It's better to extract full detail from 3 strong results than surface-level from 10 weak ones.
- **Source quality.** Prefer official company blogs, press releases, and established publications over aggregator sites.
- **Write for the next step.** The Summary should contain information that makes an email better. If a finding isn't actionable for outreach, it belongs in Key Findings, not the Summary.
- **Chinese and English.** If researching Chinese companies or markets, run queries in both languages. Different sources appear for English vs Chinese queries.
- **Verify critical claims.** If a finding seems important (pricing, dates, funding amounts), try to confirm it with a second source.
