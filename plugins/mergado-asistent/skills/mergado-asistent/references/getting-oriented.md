# Getting oriented in a project

Understand the setup before proposing anything.

## Editing vs. conversion
- Same platform in and out (e.g. `google.cz → google.cz`): you only edit the feed.
- Different platform in and out (e.g. `shopify → kaufland`): a converter builds the target format. Watch for converter side-effects (see `feed-diagnostics.md`: Meta categories).

## Detect the platform / source system
- From the project's `input_format` (e.g. `shopify.api.global` → Shopify).
- From the feed URL (e.g. `woo-product-feed-pro` → WooCommerce).

## Find real element names before writing rules
A rule needs an `element_path` that exists — never assume names. Call `list_project_elements`. Google outputs use `g:` names (`g:title`, `g:price`, `g:gtin`, `g:google_product_category`…); Heureka uses `PRODUCTNAME`, `PRICE_VAT`, `PARAM`, `CATEGORYTEXT`. Read real values with `list_unique_element_values`. For element-path syntax (nesting with `|`, conditions in `{ }`, attributes), see `element-paths-and-mql.md`.

## The data you need may already be in the feed
Before fetching anything external, check the feed itself with `list_unique_element_values` — e.g. `g:product_type` often carries the shop's own category tree, and descriptions or parameters may already hold values you can extract.

## Input names vs. output names
The output name `PRODUCTNAME` often does not exist on the input — it is built by rules. When you build a query over input data, match the original element (commonly `PRODUCT` or `NAME_EXACT`), not `PRODUCTNAME`.

## Stable identifiers for pairing & enrichment
Pair products with stable keys — `g:id` / `ITEM_ID`, `g:gtin` / `EAN`, `g:item_group_id` — and use product names only as a fallback. The same keys match external data (imports, review feeds, shop pages).

## Related projects in the same shop
A shop can hold several related projects (e.g. a product feed and a separate reviews feed) — check `list_shop_projects` before looking for data outside Mergado. A 403/404 on a project usually means a wrong id; re-check it via `list_shop_projects` before concluding it is a permissions problem.

## Back up the structure before larger changes
There is no `update_rule` and deletes are irreversible — before a bigger intervention, snapshot the current structure (`list_project_rules`, `list_project_queries`, `list_project_variables`, `list_project_elements`) so anything removed can be recreated.

## Sending a feed to Google — avoid duplicate projects
If the user already has a Google Merchant Center project in Mergado, do not create a new project from the source URL. Tell them to copy that project's **output feed URL** into GMC.

## Creating a new project
`create_project` requires a reachable source URL (Mergado validates it). Prefer reusing an existing project's output over creating duplicates.
