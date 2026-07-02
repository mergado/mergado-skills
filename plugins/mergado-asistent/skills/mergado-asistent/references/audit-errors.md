# Audit & errors — mapping problems to solutions

When diagnosing, verify reality through the MCP (`list_project_elements`, `list_unique_element_values`, `query_products`, logs) — never read the raw feed.

## GMC / Google: missing GTIN
- Check `list_project_elements` for `g:gtin`.
- Fixes: *Rewrite* (map from `EAN`); *Data File Import* (CSV of GTINs); or set `g:identifier_exists = no` for custom products.
- Note: the "Audit app" via `list_project_apps` is currently unreliable (returns empty) and `create_feedaudit` returns 500 — rely on `list_project_elements` / `query_products` instead.

## Heureka: categories & pairing
- Pull real categories with `list_unique_element_values` on `CATEGORYTEXT`.
- Map them with *Rename Categories in Bulk* (`create_categories_rule`).
- Replacing a broken mapping? `delete_rule` the old one first to avoid conflicts.

## Stale data on the platform (old prices in GMC)
- This is asynchronous, not a Mergado error. Mergado publishes the output feed; the platform fetches on its own schedule.
- Confirm Mergado regenerated: product-level `output_changed_at`; project `data_updated_at` / `rules_changed_at`.
- Then advise the user to trigger a fetch on the platform (e.g. "Fetch now" in GMC).

## Zero imported products
- `get_import_logs` / `get_import_log`. No error but `items_processed = 0` → format mismatch (e.g. project expects `<SHOPITEM>`, source sends `<ITEM>`).
- Input format can't be changed by the user → fix the source, new project, or support.

## Empty parameter tags (e.g. `<PARAM></PARAM>` on GLAMI)
- Some systems emit empty tags; Mergado passes them through.
- Fix with *Remove Parameter Values* (`create_params_remove_by_value_rule`) or by hiding the element (`hidden` attribute).
- **Do not use *Hide Product*** — it removes whole products, not empty tags.

## Meta catalog: categories overwritten
- An automatic `format_converter` can translate categories into `g:google_product_category`, which Meta rejects.
- No MCP pause (`update_rule` doesn't exist) → `delete_rule` or pause in the UI, or feed Meta from a different project.

## Missing shipping (Zboží.cz `DELIVERY_ID`)
- Segment products by price with `create_project_query` (`PRICE_VAT < 100` vs `>= 100`).
- Compose shipping with *Set Shipping Rates* (`create_batch_delivery_rule`).

## Product Data Audit (Mergado)
- The Knowledge Base "Product Data Audit" section documents feed quality checks and Google validators. See `feed-audit.md` for MCP access and current limitations.
