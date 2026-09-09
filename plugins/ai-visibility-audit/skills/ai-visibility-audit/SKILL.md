---
name: ai-visibility-audit
description: >
  Audit an online store's readiness to be discovered, cited, and recommended by AI chat
  assistants and shopping agents (ChatGPT, Claude, Gemini, Perplexity, Google AI Overviews /
  AI Mode). Combines a live technical probe of the public website (robots.txt, structured
  data, llms.txt, MCP/UCP discovery) with internal data from every connected source — Mergado
  MCP (all projects of the shop), Google Merchant Center MCP, Search Console MCP — into a
  single fixed-format report. Use whenever someone asks to check, audit, or improve their
  store's "AI visibility", "AI SEO", "GEO", "AEO", "generative engine optimization", how
  findable they are in ChatGPT/Claude/Gemini/Perplexity, or whether their product feed is
  ready for AI shopping. Works standalone, but every additional connected MCP source upgrades
  report rows from outside-guess to real data.
---

# AI Visibility Audit

Audits how well a specific online store is set up to be crawled, understood, cited, and
recommended by AI systems — Google (AI Overviews / AI Mode), OpenAI (ChatGPT), Anthropic
(Claude), Perplexity, and cross-platform machine interfaces (MCP, UCP).

The audit layers evidence from up to four sources. Only the first is always available; each
additional connected source replaces outside guesses with real data:

| Source | Availability | What it adds |
|---|---|---|
| Public website probe | always | what AI crawlers/agents actually see from outside |
| **Mergado MCP** | if connected | feed truth across ALL the shop's projects/channels: attribute completeness, broken rules, stale syncs, cross-channel inconsistencies |
| **Google Merchant Center MCP** | if connected | free-listings opt-in, disapprovals, attribute completeness score, AI Performance Insights / Share of Voice |
| **Search Console MCP** | if connected | real indexing status of product URLs, queries, sitemap coverage |

The output is deliberately the **same fixed shape every time** — same intro, same table rows,
short recommendations only. Different stores get different findings, never a different report
structure. Detailed step-by-step fixes are a separate, later step, produced only if the user
asks for them.

Read `references/platform-requirements.md` before scoring anything — it is the checklist this
audit scores against. **It starts with a "Last verified" date and a freshness protocol —
follow it:** if the date is more than ~3 months old and web search is available, refresh the
volatile platform facts (the protocol lists exactly which, with source URLs) before scoring,
tell the user what changed, and suggest updating the file. The checklist *structure* never
changes per-run — only the facts inside get refreshed; that's what keeps reports comparable
across time. For the Mergado internal checks, follow `references/mergado-internal-checks.md`.
Do not rely on memory for platform specifics.

---

## Step 1 — Introduce yourself, the same way every time

Before asking anything or running anything, say what this skill is and what's about to happen.
Use this fixed framing every run — don't improvise a different one per store; people comparing
results across stores at a workshop/webinar need the same starting frame each time:

> **AI Visibility Audit** — I'll check how ready {domain, once known} is to be crawled, cited,
> and recommended by AI systems: Google (AI Overviews/AI Mode), ChatGPT, Claude, Perplexity.
> The audit runs on up to four data sources: the public website (always), plus — when
> connected — Mergado MCP, Google Merchant Center, and Search Console. **The more of these are
> connected, the more of the report comes from real data instead of outside inference**, so if
> you can connect them, do it before we start. Right now I can see: {list what is actually
> available in this session}. I'll sample a handful of pages (never the whole catalog), run a
> live technical check, and give you one report in the same fixed format every time, then a
> short list of prioritized fixes. Detailed step-by-step instructions come only if you ask
> afterward.
>
> *Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*

Check what's actually available in this session before claiming to use it — never say "I'll
pull Merchant Center data" and then not do it. If a source isn't connected, name it once in
the intro (that's the nudge) and move on — don't lecture.

---

## Step 2 — Scope: pick a sample, never audit the whole catalog

First determine which situation you're in — this changes what you need to ask.

**Mergado MCP is connected in this session:**
Identify the shop/project from context you already have (or via
`get_current_user` → `list_user_eshops` → `list_shop_projects` if you don't). The project record
gives you the store's public domain — you don't need to ask the user for it. Only ask a
clarifying question if the account has multiple shops and it isn't obvious which one they mean.

**Mergado MCP is not connected (standalone mode):**
You have no way to know which store to audit — **ask the user directly**, e.g. "Which store's
domain should I audit?" That single question is the only hard requirement to proceed. While
you're at it, it's fine to ask one optional follow-up in the same message: "Anything specific
you want prioritized — particular categories or products you're worried about — or should I
just sample automatically?" If they name specific pages, use exactly those as the sample. If
they don't, proceed with the domain alone: `scripts/audit.sh <domain>` will fetch
`sitemap.xml` itself and pick a sample automatically (see Step 5).

Either way, once you have a domain, move on to sampling:

**Do not attempt to check every product.** A store can have thousands of SKUs; this audit is
diagnostic, not exhaustive. Select a bounded, representative sample:

- the homepage
- **3–5 category pages**, chosen to span different verticals/departments if the store has more
  than one (not five pages from the same category)
- **5–8 product pages**, spanning different categories and, where visible, different price
  points (a €15 accessory and a €400 flagship product can have very different data quality)
- 1 blog/content page, if the store has one

**Hard floor: at least 3 product pages, always**, even for a tiny catalog — one product tells
you nothing about whether a pattern is consistent or a fluke. If the site genuinely has fewer
than 3 products, say that explicitly rather than silently running on 1. If the auto-sample
(Step 5) lands only on content/category pages and misses actual product detail pages, or vice
versa, add explicit paths so the sample covers both — check the sitemap yourself for real
product URLs if the automatic pick missed them.

If the catalog is small (roughly under ~30 products), sample more generously, but still state
explicitly what was and wasn't checked — this report should never imply full coverage it
doesn't have.

---

## Step 3 — Internal audit via Mergado MCP (skip if not connected)

This is a first-class audit phase, not a bonus. Follow the detailed procedures in
`references/mergado-internal-checks.md`. In summary, it covers:

1. **Project matrix** — list ALL projects of the shop (paginate `list_shop_projects` to the
   end), with channel, exported item count, `data_synced_at` age, and `is_dirty`. A feed that
   last synced months ago is exporting stale prices/availability to that channel — a direct
   AI-visibility risk on its own.
2. **Attribute completeness on the product sample** — GTIN/EAN, brand, availability,
   descriptions, via `query_products` with `values_to_extract` on the shop's main projects.
3. **Masking-rule detection** — compare `input_value` vs `value` on key elements; catch rules
   that paper over problems (e.g. `identifier_exists` yes→no) or mangle titles.
4. **Description quality** — scraped page junk, HTML remnants, cart buttons inside feed
   descriptions.
5. **Cross-channel consistency** — same product across projects (identifiers, titles, prices).
6. **AI-attribute readiness** — are `g:question_and_answer`, `g:product_highlight`,
   `g:product_detail`, `g:popularity_rank`, `g:related_product` present in the project's
   element tree, and actually populated?
7. **Existing performance elements** — custom elements carrying Search Console/analytics data
   (e.g. `CG_GOOGLE_SEARCH_*`) that reveal which products have zero search visibility.

If Mergado MCP is **not** connected, skip this step and say so plainly in the report — and
note in the sources table what connecting it would have added.

---

## Step 4 — Merchant Center & Search Console (each: skip if not connected)

**Google Merchant Center MCP (or equivalent tools), if available:** pull free-listings opt-in
status, disapproved/limited products, attribute completeness signals, and — where exposed —
AI Performance Insights (Share of Voice in AI impressions). These directly replace the "could
not verify from outside" rows of the report.

**Search Console MCP (or equivalent tools), if available:** check indexing status of the
sampled product URLs, sitemap submission state, and top queries for product pages. Zero-click
product pages corroborate (or contradict) the feed-level findings.

For both: verify the tools actually exist in this session before promising results. If absent,
one line in the sources table is enough — don't speculate about what the data "probably" is.

---

## Step 5 — Live technical probe

Run the bundled script against the sampled URLs from Step 2:

```bash
bash scripts/audit.sh <domain> [sampled-path-1] [sampled-path-2] ...
```

If you don't have specific sampled paths yet, run it with just the domain — the script will
fetch `sitemap.xml` itself and pick a sample automatically.

The script is a deterministic data-gathering step; it does not interpret anything. Read its
raw output and interpret it yourself against `references/platform-requirements.md`. In
particular, check for:

- **robots.txt** — is any AI crawler explicitly blocked (`GPTBot`, `OAI-SearchBot`,
  `ChatGPT-User`, `ClaudeBot`, `Claude-SearchBot`, `Claude-User`, `PerplexityBot`,
  `Google-Extended`)? Blocking a *training* crawler does not block *live retrieval* bots —
  they're independent toggles; check each by name, don't assume.
- **Server-rendered content** — is the product name/price/description present in the raw HTML,
  or only in a JS shell?
- **Structured data** — which schema.org types appear (JSON-LD and/or microdata), and is
  `AggregateRating`/`Review` present anywhere in the sample? Its complete absence across all
  sampled products is a real, common gap — call it out plainly.
- **Identifiers** — GTIN/EAN/MPN present, or only an internal SKU?
- **llms.txt** — populated, an auto-generated empty stub (0 bytes), or genuinely absent (404)?
  All three are distinct; name which one you found.
- **`/.well-known/ucp`** and **MCP probe paths** — almost always absent (or 403 from generic
  WAF hardening) for stores not on Shopify or a UCP-integrated platform; expected, not a
  defect (see reference doc).
- **Redirects and locale/currency quirks** in the headers section (bare domain → www, default
  language cookie mismatching the store's market) — the script resolves the effective host
  automatically, but a surprising redirect target or locale default deserves a line in the
  report.

---

## Step 6 — Score against platform requirements

Cross-reference Steps 3–5 findings against `references/platform-requirements.md`, section by
section. Note which platforms are gated by which specific gaps — e.g. "no GTIN" affects Google
Shopping Graph matching *and* Perplexity merchant matching, while "no AggregateRating" affects
recommendation confidence broadly but blocks nothing outright.

Where internal and external evidence overlap, **connect them explicitly** — "GTIN missing on
the website AND empty in the source feed across all channels" is a much stronger, more
actionable finding (fix it once, at the source) than either observation alone.

Do not invent platform requirements beyond what's in the reference doc or clearly verifiable.

---

## Step 7 — Write the report (fixed template — no exceptions)

Follow `references/report-template.md` exactly — same section order, the sources table first,
then the same findings table with the same fixed rows every time. A row that's not applicable
still appears, marked accordingly — dropping rows breaks comparability between audits.

The report must:

- Open with the Step 1 introduction, then the **Connected data sources** table (which of the
  four sources were live for this run, and one line on what each missing one would add), then
  what was sampled.
- Fill in the fixed findings table — one row per checklist item, every time. When Mergado MCP
  ran, the internal findings get their own section below the table (project matrix + feed
  findings), and row 13 summarizes it.
- List recommendations as a **short, numbered list of one-liners only** — name the concrete
  field/file/attribute, not the step-by-step "how". That's Step 8, on request.
- Rank recommendations by impact vs. effort, top 5.
- Be honest about what could *not* be checked, and which missing connection would unlock it.
- End with the fixed closing question from the template.
- **No bare jargon** for the genuinely new mechanisms — rows for llms.txt / MCP / UCP carry
  their fixed explainer text from the template, worded the same way every time. Established
  e-commerce terms (robots.txt, sitemap, EAN, feed) need no explanation for this audience.

Offer to save the report as a file, and — if the environment supports it — publish it as a
shareable page.

---

## Step 8 — Action plan (only after the user asks)

Do not do this unprompted. Only after the user responds to the closing question — naming one,
several, or "all" of the numbered recommendations — expand exactly those into concrete action
steps, following `references/action-plan-template.md`.

If they ask for all of them, still present each as its own clearly separated block. No
credits claim here — it already ran in the announcement and the report footer. If a fix
depends on something outside this skill's reach (a Mergado rule, a Merchant Center setting, an
e-shop platform template), say which tool or account is needed rather than describing it
vaguely. When Mergado MCP is connected and the fix is feed-side, propose the specific Mergado
rule (and offer to create it — with the user's explicit confirmation, never automatically).
