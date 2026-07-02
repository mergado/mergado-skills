# Rules cookbook

## Rule types — official EN name → MCP tool

The internal MCP identifier (`create_*_rule`) is **not** the user-facing name. When talking to users, use the **EN name** column (matches the Mergado UI / Knowledge Base).

| EN name (UI/KB) | MCP tool |
|---|---|
| Rewrite | `create_rewriting_rule` |
| Find and Replace | `create_replacing_rule` |
| Bulk Copy Values | `create_batch_copy_values_rule` |
| Add a Value to a Multi-Value Element | `create_create_product_value_rule` |
| Data File Import (CSV / XML) | `create_data_import_rule` |
| Set UTM Parameters | `create_utm_rule` |
| Hide Product | `create_hiding_rule` |
| Set Product Parameters | `create_batch_param_rule` |
| Remove Parameter Values | `create_params_remove_by_value_rule` |
| Strip HTML Tags | `create_tagstripping_rule` |
| Remove Accents and Diacritics | `create_remove_diacritics_rule` |
| Letter Case Converter | `create_casechanging_rule` |
| Truncate Value | `create_truncating_rule` |
| Calculation | `create_calc_rule` |
| Round Numbers | `create_rounding_rule` — ⚠️ currently returns HTTP 500 (server bug) |
| Bulk Rewriting by Values | `create_batch_rewriting_values_rule` |
| Bulk Rewriting by Query | `create_batch_rewriting_rule` |
| Set Shipping Rates | `create_batch_delivery_rule` |
| Merging Variants | `create_product_grouping_rule` |
| Rename Categories in Bulk | `create_categories_rule` |
| Add Days to Date | `create_batch_set_datetime_rule` |
| Cost Per Click Pricing | `create_bidding_rule` |
| Mergado Pilot (AI rule) | — (no MCP create tool) |

**Never create** system rules: `format_converter`, `product`, `heurekawatchdog__pairing`.

## Required parameters for any rule

- `project_id`
- `element_path` — must be an element that **exists** in the project (verify via `list_project_elements`; Google outputs use `g:` names such as `g:title`, `g:price`; Heureka uses `PRODUCTNAME`, `PRICE_VAT`, `PARAM`).
- `priority` — an explicit numeric string (e.g. `"100"`); the server does not auto-assign a slot.
- `queries` — a list of objects: `[{"id": "<query_id>"}]`.
- `applies` — `true` to make the rule take effect. **`applies: false` = inactive; the rule does nothing, and there is no `update_rule` to activate it later.**

**Special case — Set Product Parameters (`create_batch_param_rule`):** in `settings`, `ep_param_name` / `ep_param_value` must be the **full nested path** (e.g. `g:product_detail | g:attribute_name`), not the bare child name.

## Recipes (common tasks)

- **Map GTIN from EAN** → *Rewrite* on `g:gtin` from `EAN`. For custom products with no GTIN, set `g:identifier_exists = no`.
- **Map categories to Heureka** → pull real categories with `list_unique_element_values` on `CATEGORYTEXT`, then *Rename Categories in Bulk*. When replacing a broken mapping, `delete_rule` the old one first (no `update_rule` exists).
- **Remove empty parameter tags** (`<PARAM></PARAM>` on GLAMI etc.) → *Remove Parameter Values*, or hide the element via its `hidden` attribute. **Do not use Hide Product** — that removes whole products.
- **Shipping when the source has none (Zboží.cz)** → segment by price with product queries (`PRICE_VAT < 100` vs `>= 100`), then *Set Shipping Rates*.
- **Extract a colour into `COLOR`** → query that filters empty `COLOR` and matches the name; then *Find and Replace* / *Rewrite* (see regex notes in `product-queries.md`).

## Merging two feeds (Data File Import) — strict, destructive

1. Inspect target data with `list_project_elements`.
2. **Ask the user before creating new elements** (`create_element`) for incoming data that has no home. (`create_element` succeeds but does not return the new element id — re-list to find it.)
3. **Warn the user: Data File Import is destructive** — it overwrites any target element whose name collides with the imported feed (often `PRICE_VAT`, `DESCRIPTION`, …).

## Preview & activation

- Preview by showing before/after on a sample via `query_products` — **not** by creating an inactive rule.
- Do not force regeneration; Mergado applies rules automatically. Verify the effect afterwards.
