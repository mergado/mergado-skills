# Platform requirements reference

**Last verified: 2026-08-12** ← update this date whenever the volatile facts below are
re-checked against current sources.

This is the checklist the audit scores against. It is a condensed, English distillation of
verified research (official Google/OpenAI/Anthropic documentation plus corroborated 2026 field
reporting). If a finding doesn't clearly map to something below, say so in the report rather
than inventing a rule.

## Freshness protocol (read this first)

The **checklist structure is stable** — what to check (crawlability, structured data,
identifiers, reviews, feed freshness, llms.txt/MCP/UCP status) doesn't churn. The **facts
inside are not** — platform programs, protocol adoption, and official stances change within
months.

Before scoring an audit, check the "Last verified" date above:

- **Under ~3 months old** → use this file as-is.
- **Older than ~3 months, and web search is available** → run a bounded refresh (a few
  searches, not a research project) of the VOLATILE items only:
  1. OpenAI: current state of the ACP product feed / ChatGPT merchant program
     (`developers.openai.com/commerce`), and the crawler list (`developers.openai.com/api/docs/bots`)
  2. Google: Merchant Center conversational/AI attributes and AI-visibility guidance
     (`support.google.com/merchants`, `developers.google.com/search/docs/appearance/ai-features`)
  3. Perplexity: merchant program status and feed requirements
  4. llms.txt: whether any major AI system has *started* reading it in production (Google's
     stance especially)
  5. MCP/UCP commerce adoption: whether platforms beyond Shopify now expose storefront MCP /
     UCP manifests by default, and whether Anthropic has launched any merchant program
  Apply what you find on top of this file, tell the user what changed, and recommend updating
  this file (with a new "Last verified" date) so future runs start current.
- **Older than ~3 months, and web search is NOT available** → proceed with this file, but say
  so in the report: "reference data last verified {date}; fast-moving platform facts may have
  changed since."

The STABLE items (universal baseline: crawlability mechanics, schema.org types, GTIN,
server-side rendering, review signals) don't need re-verification — don't burn time
re-searching fundamentals.

---

## Universal baseline (applies to every platform)

- **Crawlability**: no AI crawler blocked in `robots.txt` unless that's an intentional
  business decision. Named bots to check individually — blocking one does not imply blocking
  another, they are independent toggles:
  - OpenAI: `GPTBot` (training), `OAI-SearchBot` (live ChatGPT Search retrieval — separate from
    training), `ChatGPT-User` (user-triggered browsing), `OAI-AdsBot` (ad landing page checks).
  - Anthropic: `ClaudeBot` (training), `Claude-SearchBot` (search indexing), `Claude-User`
    (live, user-triggered fetch).
  - Perplexity: `PerplexityBot`.
  - Google: `Google-Extended` (training opt-out only — does **not** gate Merchant
    Center/Shopping/AI Mode eligibility, which runs through the separate Merchant Center feed
    pipeline and standard Googlebot indexing).
- **Server-rendered content**: product name, price, availability, and description must be
  present in the raw HTML response, not injected only by client-side JavaScript.
- **Structured data**: `Product` + `Offer` + `AggregateRating` + `Review` + `BreadcrumbList`
  schema.org markup, ideally as JSON-LD (more reliably parsed than microdata, though microdata
  is valid). Markup must match the page's visible content exactly — mismatches get discounted
  or ignored.
- **Stable identifiers**: GTIN/EAN/UPC or MPN present, not just an internal SKU. Needed for
  matching across Shopping Graph / other catalogs.
- **Reviews on more than one surface**: on-site reviews plus at least one independent platform
  (Google, Trustpilot, a category-specific comparison site). AI systems weight cross-platform
  consistency higher than a large volume of only-on-site reviews.
- **Freshness**: live, accurate price/availability data. Stale feeds are a commonly cited
  reason products get dropped from AI shopping surfaces.

---

## Google (AI Overviews / AI Mode / Merchant Center / Shopping Graph)

- Google's own position: **no special "AI schema" or extra markup exists** — AI Overviews/AI
  Mode eligibility piggybacks entirely on standard Search/Shopping eligibility (indexing,
  snippet eligibility, policy compliance).
- For shopping queries specifically, AI Mode/Overviews draw from the **Shopping Graph**, which
  is populated by **Merchant Center feeds** — free listings must be opted in, or the product
  isn't in the Shopping Graph at all and can't surface organically, regardless of on-site
  quality.
- `product_highlight` (2–100 short benefit bullets) and `product_detail` (structured
  section/attribute/value triples) are called out by Google as directly feeding AI-generated
  answers — worth checking whether these are populated in the feed, not just the description.
- 2026 "conversational attributes" (optional, additive): `question_and_answer` (up to 30 Q&A
  pairs/product), `document_link` (spec PDFs), `related_product`, `item_group_title`,
  `variant_option`, `popularity_rank`. Absence isn't a blocker, but relevant for
  higher-consideration categories.
- Image resolution: minimum 500×500px enforced from **January 31, 2027** (warnings from April
  2026) — worth flagging if product imagery is smaller.
- **AI Performance Insights** (Merchant Center reporting, 2026) shows a per-account "attribute
  completeness score" and Share of Voice vs. similar competitors in AI impressions — if the
  merchant has Merchant Center access, this is a more authoritative completeness signal than
  anything inferable from the outside.

---

## OpenAI / ChatGPT

- ChatGPT shopping results are drawn from a mix of (a) a dedicated **Agentic Commerce Protocol
  (ACP) product feed** submitted via `chatgpt.com/merchants` (CSV/JSON; required fields include
  `item_id`, `title`, `description`, `url`, `brand`, `image_url`, `price`+currency,
  `availability`, `is_eligible_search`/`is_eligible_checkout`, `seller_name`/`seller_url`), and
  (b) general live web retrieval. The ACP feed is a **feed-management concern**, not something
  visible from the website itself — flag it as a recommendation, not something this audit can
  directly verify from the outside.
- On the website side: `OAI-SearchBot` must be allowed for live ChatGPT Search visibility —
  independent of whether `GPTBot` (training) is blocked.
- Note (2026): OpenAI discontinued in-chat **Instant Checkout** around March 2026 after limited
  merchant adoption; the ACP **product feed** for discovery/comparison remains live and is the
  durable part of this integration. Don't over-index on checkout-specific claims.
- For agentic/browsing scenarios (ChatGPT Atlas), clear, semantically labeled interactive
  elements (ARIA roles/labels on buttons, forms, menus) help the agent act correctly on the
  page — a general web-accessibility best practice that also happens to matter here.

---

## Perplexity

- Perplexity's merchant program reuses the **same product feed specification as Google
  Merchant Center** (CSV via SFTP, or XML/RSS 2.0) — a store with a solid Merchant Center feed
  is a short step from Perplexity enrollment, not a separate integration.
- Schema.org `Product`+`Offer`+`Review`+`AggregateRating` and GTIN are explicitly called out as
  required for matching/quality.
- Even outside the formal merchant program, Perplexity's agentic browser (Comet) can still
  shop by crawling the open web — meaning general on-page hygiene still matters for products
  not formally enrolled.

---

## Anthropic / Claude

- As of August 2026, **no merchant program, feed spec, or dedicated shopping integration
  exists** for Claude. Visibility depends entirely on:
  - generic crawlability and accurate on-page structured data (the universal baseline above),
  - and, for agentic/tool-use scenarios, an **explicitly configured MCP connector** — there is
    no ambient discovery mechanism where Claude "finds" a store's MCP server on its own. A
    merchant's MCP server (if one exists) only gets used if a user or an integration
    deliberately points a Claude client at it.
- Claude's web search tool is reported (third-party analysis, not officially confirmed) to run
  on **Brave Search**, a different index than Google/Bing — worth a spot-check if a client
  cares specifically about Claude visibility, since it may behave differently from Google/GPT
  results for the same query.

---

## Cross-platform machine interfaces: MCP, UCP, llms.txt

- **MCP (Model Context Protocol)** is a generic tool-calling transport with **no built-in
  commerce semantics**. It only produces AI visibility when either:
  1. a platform (e.g. Shopify) has a **business-level catalog-syndication partnership** with
     an AI provider (this is how Shopify's "Agentic Storefronts" reach ChatGPT/Google AI
     Mode-Gemini/Microsoft Copilot/Perplexity automatically — verified sources do **not**
     list Claude among the platforms Shopify syndicates to as of mid-2026), or
  2. a user/developer **explicitly configures** an MCP connector pointing at that server
     (manual setup in Claude/ChatGPT settings — not automatic).
  A store having an MCP endpoint live and public is necessary but not sufficient for any AI
  visibility benefit — it needs one of the two paths above.
- **UCP (Universal Commerce Protocol)**, Google-driven: discovery via a static
  `/.well-known/ucp` JSON manifest declaring supported capabilities and endpoints. Read only by
  agents explicitly built on UCP (currently Google's ecosystem plus named partners: Shopify,
  Etsy, Wayfair, Target, Walmart, Stripe, Visa, Mastercard, and others). This is a
  **transactional/checkout discovery mechanism, not a general AI-recommendation lever** — its
  presence doesn't make a product more likely to be *recommended*, only more likely to be
  *transactable* once an agent already intends to buy from that domain.
- **llms.txt**: cheap to add, but as of 2026 **no major AI crawler is confirmed to read it in
  production** (Google has explicitly said it has no effect on Search/AI Overviews; independent
  studies found ~0 genuine AI-bot requests to `/llms.txt` across large samples). Roughly 40% of
  existing `llms.txt` files across the web are empty auto-generated stubs with no real content
  — **always check size, not just presence**. Treat as a low-priority checkbox item, never as
  a headline recommendation.
