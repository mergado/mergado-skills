# Mergado internal checks — procedures for Step 3

These checks run only when Mergado MCP is connected. They are what turns this audit from an
outside guess into feed truth. Keep tool usage bounded: paginate listings to completion, but
sample products (10–25 per project on the main projects), never dump whole catalogs.

## 1. Project matrix (all projects, always)

`list_shop_projects` for the chosen shop — **paginate to the end** (check `total_results` vs
returned count; use `offset` until you have all). For each project record:

- name + `output_format` (the channel)
- `exported_items`
- `data_synced_at` → compute age. **Flag anything older than ~7 days**; months-old syncs are a
  headline finding (that channel is being fed stale prices/availability).
- `is_dirty` (pending regeneration) and `is_paused` / `turned_off`
- `pairing_elements` — worth noting when a project pairs on EAN: it implies identifiers are
  expected somewhere in that pipeline.

Present as a compact table in the report's internal section. The matrix alone often reveals
the store's channel strategy (which AI-relevant channels exist — Google, Facebook, Heureka,
Zboží — and which are missing or rotting).

## 2. Attribute completeness (product sample per main project)

Pick the 1–3 most AI-relevant projects (Google Shopping first, then marketplace/comparison
channels). For each, `query_products` on the project's `all_products_query_id` with
`values_to_extract` for the key elements — for a Google-format project typically:
`g:id, g:title, g:gtin, g:mpn, g:brand, g:availability, g:google_product_category`.

Count per attribute: filled / empty over the sample. Report as "X of N sampled products".
Empty GTIN **and** empty brand across the whole sample is a source-data problem, not a rule
problem — say which.

## 3. Masking-rule detection (input_value vs value)

In `query_products` responses, elements carry both `input_value` (before rules) and `value`
(after rules) when a rule changed them. Scan the sample for:

- **`g:identifier_exists` rewritten `yes` → `no`** — a rule papering over missing GTINs.
  Google then treats products as having no standard identifier, which limits Shopping Graph
  matching. This is a masking fix, not a real fix — always call it out.
- **Title transformations that break output** — e.g. brand stripped but separators left behind
  (`"Brand | K14 | Product"` → `"| K14 | Product"`). Compare input vs output titles on the
  sample; orphaned separators, truncations, or leading/trailing junk are concrete rule bugs
  with the exact product ID as evidence.
- Any other suspicious rewrite where the output is plainly worse than the input.

## 4. Description quality

Read the description values in the sample (the actual text, not just presence). Red flags:

- scraped page fragments: "Add to cart" / "Přidat do košíku", related-product blocks,
  navigation text, prices of *other* products inside a description
- heavy HTML remnants, entity soup, tab/whitespace runs
- near-empty descriptions (a sentence or less) on flagship products

AI assistants read these descriptions verbatim — a description containing another product's
name and price actively misleads the model. Quote one short concrete example in the report
(one line, truncated), don't paste walls of feed text.

## 5. Cross-channel consistency

Take 3–5 products present in multiple projects (match by product URL or ID) and compare
across projects: identifiers, titles, price, availability. Report concrete divergences —
"same product: 'X' on Google, 'Y' on Heureka" — because inconsistent titles/identifiers across
channels undermine entity matching in Google's Shopping Graph and Perplexity's dedup.

## 6. AI-attribute readiness

From `list_project_elements` on the Google-format project, check whether these exist in the
element tree, and from the product sample whether they're actually **populated** (existing but
empty = available-but-unused, which is an opportunity, not a defect):

- `g:product_highlight`, `g:product_detail` (long-standing, directly feed AI answers)
- `g:question_and_answer`, `g:related_product`, `g:item_group_title`, `g:variant_option`,
  `g:popularity_rank`, `g:document_link` (2026 conversational attributes)

"Structure supports them, nothing fills them" is a common and useful finding — it means the
upgrade path is pure feed rules, no platform migration.

## 7. Existing performance elements

Look for custom/manual elements carrying analytics data (naming varies; e.g.
`CG_GOOGLE_SEARCH_CLICKS`, `CG_GOOGLE_SEARCH_CTR`, `CG_GOOGLE_SEARCH_IMPRESSIONS`, or similar).
If present, extract them for the sample: products with zero impressions/clicks are the
concrete "invisible products" list — lead the internal findings with it when it exists. Note
this is also evidence the shop already pipes Search Console data into Mergado, which is worth
one approving line (it's exactly the kind of integration this audit recommends).

## Reporting notes

- Every claim gets a number ("0 of 10 sampled products have GTIN"), never "mostly missing".
- Findings that match an external (website) finding should be cross-referenced explicitly —
  "empty in the feed AND absent on the website" means fix-at-source.
- Do not modify anything — this is a read-only audit. Rule creation belongs to Step 8, only
  with the user's explicit confirmation.
