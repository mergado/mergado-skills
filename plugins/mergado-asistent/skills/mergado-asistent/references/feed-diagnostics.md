# Feed diagnostics — problem to fix

Verify reality with the tools (never read a feed already in Mergado). Confirm scope with `query_products` before proposing a fix.

## Zero imported products (feed download)
Check `get_import_logs` → `get_import_log`. If it does not error but `items_processed = 0`, it is usually a **format mismatch** — the project expects one root element (e.g. `<SHOPITEM>`, Heureka) but the source sends another (e.g. `<ITEM>`, Mergado). The input format of an existing project cannot be changed by the user → advise fixing the source, a new project, or Mergado support.

## Data File Import rule — 0 products matched
`get_apply_logs` shows `processed_products: 0` with no reason. Usually the CSV key column name ≠ the project element (CSV matches by header = element path, and the matching-column params are silently dropped). Fix with the helper-element workaround in `rules-cookbook.md` (create element named like the column → copy the real key into it → import with `match_by_input_values: false`).

## Stale data on the platform (old prices/stock)
This is asynchronous, not a Mergado error. Mergado only publishes the output feed; the platform fetches on its own schedule. Confirm Mergado regenerated (product-level `output_changed_at`; project `data_updated_at` / `rules_changed_at`), then tell the user to trigger a fetch on the platform (e.g. "Fetch now" in Google Merchant Center).

## GMC rejections — missing GTIN
Check `list_project_elements` for `g:gtin`. Fix with *Rewrite* (map from `EAN`) or *Data File Import* (CSV). If a product genuinely has no GTIN/EAN, setting `g:identifier_exists = no` is an option — but **ask the user first**; even custom products can have an EAN.

## Two elements with swapped values (e.g. `g:price` ↔ `g:sale_price`)
Applies to any pair of elements whose values ended up in each other's place. Diagnose with a query comparing the two elements (e.g. `g:sale_price > g:price` — numeric comparison works). Fix with the swap recipe in `rules-cookbook.md` (helper element; a naive two-step copy overwrites the first value).

## Wrong availability values on the output
Compare input vs output values with `list_unique_element_values` (e.g. input `backorder` leaving the output as `preorder`). The cause is usually an existing mapping rule — find it via `list_project_rules` / `get_rule`, then override it with a higher-priority rule or `delete_rule` the wrong one (with user consent).

## Missing descriptions or images for a subset of products
Scope it with a query (`DESCRIPTION = ''`, empty `g:image_link`) — the affected set is often one brand/category with incomplete source data. Descriptions can be composed from existing elements (*Rewrite* with `%element%` references). Image URLs must exist in the source or come from the user — **never guess or fabricate URLs**.

## Empty parameter tags (`<PARAM></PARAM>`)
Some source systems emit empty tags and Mergado passes them through to any output format. Fix with *Remove Parameter Values*, or hide the element via its `hidden` attribute. Do **not** use *Hide Product* — that removes whole products.

## Meta catalog — shop categories replaced by Google taxonomy
Meta **accepts (and prefers) the Google product taxonomy** in `google_product_category` (full path or numeric id; `fb_product_category` is the alternative) — that field itself is not an error. The real problem is losing the shop's **own** category structure: an automatic `format_converter` rule may translate the original categories into English Google-taxonomy values. The converter is a system rule (`is_deletable: false`) and cannot be paused via the MCP — options: keep the original categories in another element (e.g. `product_type` or a custom label) via *Rewrite*, ask the user to adjust or pause the converter in the editor, or feed Meta from a different project.

## Missing shipping information
Segment products by price with `create_project_query` (e.g. `PRICE_VAT < 100` vs `>= 100`), then compose shipping with *Set Shipping Rates* (`create_batch_delivery_rule`).

## Can't verify the effect in this session
Rebuilds are automatic but can take minutes to hours; do not force them (no `mark_*_dirty`). A freshly created query also reports `product_count: null` until the first rebuild. Tell the user the change is deployed and will show after the next rebuild (or after they run it manually in the UI) — don't present "0 results yet" as a failure.

## Reading a Product Data Audit
Existing audits are readable: `list_project_feedaudits` → `get_feedaudit` → `list_feedaudit_issues` / `get_feedaudit_issue`, and `list_feedaudit_products` → `get_feedaudit_product` → `list_feedaudit_product_issues`. Use them to explain concrete feed problems and map them to the fixes above. (Creating a new audit via `create_feedaudit` currently fails — see `known-limitations.md`.)
