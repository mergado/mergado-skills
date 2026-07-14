# Rules cookbook

## Rule types — official name → MCP tool
Use the **name** column when talking to users (it matches the Mergado UI). The `create_*_rule` identifier is internal.

| Name (UI) | MCP tool |
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
| Round Numbers | `create_rounding_rule` |
| Bulk Rewriting by Values | `create_batch_rewriting_values_rule` |
| Bulk Rewriting by Query | `create_batch_rewriting_rule` |
| Set Shipping Rates | `create_batch_delivery_rule` |
| Merging Variants | `create_product_grouping_rule` |
| Rename Categories in Bulk | `create_categories_rule` |
| Add Days to Date | `create_batch_set_datetime_rule` |
| Cost Per Click Pricing | `create_bidding_rule` |

## Creating a rule — general principles
Each `create_*_rule` tool defines its own required fields and payload structure in its schema and description — **the schema is authoritative and may evolve, so read it before calling** rather than relying on this list. Principles that hold across rule types:
- `element_path` must point to an element that **exists** in the project (verify with `list_project_elements`).
- `priority` controls ordering (numeric string; lower priority is applied earlier). If the server does not assign one automatically, pass it explicitly (e.g. `"100"`).
- `queries` scope the rule to products — a list of objects `[{"id": "<query_id>"}]`.
- `applies: true` makes the rule take effect. There is no `update_rule`, so an inactive or misconfigured rule is replaced with `delete_rule` + create.
- **Set Product Parameters** (`create_batch_param_rule`): in `settings`, `ep_param_name` / `ep_param_value` must be the **full nested path** (e.g. `g:product_detail | g:attribute_name`), not the bare child name.

## Rule-specific gotchas (observed in real sessions / UI)
- **Bulk Rewriting by Values (`create_batch_rewriting_values_rule`): the two element-path fields are reversed vs. their names.** Top-level `element_path` = where the value is **written**; `data.target_element_path` = where the value is **searched**. Getting them the wrong way can silently write into the wrong element (even a pairing key). After creating, read the rule back with `get_rule` and verify the effect on a sample after the next rebuild.
- **Rename Categories in Bulk (`create_categories_rule`) is bound to the format's category element** (e.g. `g:google_product_category`) and **ignores a custom `element_path`** (the API even echoes it back). To map into a custom element, use *Bulk Rewriting by Values* instead.
- **Add a Value to a Multi-Value Element (`create_create_product_value_rule`) fills only empty values** — it never overwrites. Use it as a fallback: give it a later (higher) priority than rules that write specific values.
- **No `update_rule`** — to change a rule you `delete_rule` + create again (you lose its id).

## Recipes
- **GTIN missing (GMC):** check `g:gtin` in `list_project_elements`. Fix with *Rewrite* (map from `EAN`) or *Data File Import* (CSV of GTINs). If a product genuinely has no GTIN/EAN, setting `g:identifier_exists = no` is an option — but **ask the user first**; even custom products can have an EAN.
- **Map categories to a platform taxonomy:** pull the shop's real categories with `list_unique_element_values` (e.g. on `CATEGORYTEXT` or `g:product_type`), then map them — *Rename Categories in Bulk* for the format's category element, or *Bulk Rewriting by Values* for a custom element. Match against the platform's official taxonomy: Heureka category tree https://www.heureka.cz/direct/xml-export/shops/heureka-sekce.xml (simplest: write the category id), Google product taxonomy with IDs — en-US https://www.google.com/basepages/producttype/taxonomy-with-ids.en-US.txt, cs-CZ https://www.google.com/basepages/producttype/taxonomy-with-ids.cs-CZ.txt. Replacing a broken mapping? `delete_rule` the old one first.
- **Empty parameter tags (`<PARAM></PARAM>`):** use *Remove Parameter Values* or hide the element via its `hidden` attribute. Do **not** use *Hide Product* — that removes whole products.
- **Missing shipping:** segment by price with product queries (e.g. `PRICE_VAT < 100` vs `>= 100`), then *Set Shipping Rates*.
- **Extract a value (e.g. colour) into an element:** either a *Find and Replace* with a capture group and a `\1` reference, or a **variable** (`create_variable` with `regular_expression` + `fragment_number` = the group number) referenced as `%VARIABLE%` in a rule. See `element-paths-and-mql.md`.
- **Swap two values:** one multi-row *Rewrite* (backup → overwrite → restore; rows run in order), or *Bulk Copy Values* through a temporary element.
- **Google AI elements (e.g. `g:question_and_answer`):** write directly to the nested paths with *Bulk Rewriting by Query* rows (`g:question_and_answer | g:question`, `g:question_and_answer | g:answer`). *Set Product Parameters* writes into the format's parameter structure (`g:product_detail`) unless its `ep_*` settings are redirected with **full nested paths** — a naive attempt lands in parameters, not the target element.

## Data File Import (CSV / XML) — destructive; extra CSV caveats
1. Inspect target data with `list_project_elements`.
2. **Ask the user before creating new elements** with `create_element` for incoming data that has no home. (`create_element` doesn't return the new id — re-list to find it.)
3. **It is destructive:** a colliding target element name is **overwritten** (often `PRICE_VAT`, `DESCRIPTION`).
4. **Use a public `source_url`** (e.g. a Google Sheet CSV export `?format=csv&gid=`). Base64 **upload is silently discarded**.
5. **CSV matching is by header name = element path.** `file_matching_element_path` / `project_matching_element_path` are dropped for CSV (returned `null`), so if the CSV key column has a different name than the project element, the import matches nothing (0 processed, still reports "success"). Workaround: `create_element` named exactly like the CSV column → `create_batch_copy_values_rule` (real key → that element, low priority) → `create_data_import_rule` with `match_by_input_values: false`.
6. **`match_by_input_values`:** `true` = match on original input values only (an element filled by a rule will not match); `false` = match on current values after earlier rules. Use `false` when the key is filled by a copy rule.
7. **Duplicate CSV column names lose data** — only the last is kept; don't use CSV import for multi-value elements.
8. **`matching_mode`** enum is `xid / exact / contains` (the schema description is wrong).
9. **The matching key must also exist in the source feed** — verify the source's real field names first (e.g. a review feed had `product_url`, not `link`). Field paths (`file_matching_element_path`, `elements_to_skip`) are validated against the **target project's** elements, so create a target element for every imported field before creating the rule.

## Preview & apply
Preview with `query_products` (before/after on a sample), not an inactive rule. Do not force regeneration — Mergado applies rules automatically; verify the effect afterwards.
