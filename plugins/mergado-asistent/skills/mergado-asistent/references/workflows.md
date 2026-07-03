# Workflows — step-by-step playbooks

Every playbook follows the universal workflow: understand → orient (MCP) → diagnose & propose → act after consent → verify. Never force regeneration; never read raw feeds.

## A. First contact / orientation
1. `get_current_user`.
2. `list_user_eshops(user_id)` → if several, ask which e-shop.
3. `list_shop_projects(shop_id)` → identify the project (editing vs. conversion — see glossary).
4. Summarise what you see in plain language before proposing anything.

## B. "Google rejected my products"
1. Identify the project and the rejected attribute (from the user's message / GMC).
2. `list_project_elements` — is the required element present (e.g. `g:gtin`)?
3. `list_unique_element_values` / `query_products` — how many products are affected?
4. Propose a fix (see `rules-cookbook.md` / `audit-errors.md`), show a before/after sample via `query_products`.
5. After consent, create the rule (`applies: true`, real `element_path`, numeric `priority`, `queries=[{"id":…}]`).
6. Verify the selection; explain that Mergado applies rules automatically and the platform must re-fetch.

## C. "My feed is empty"
1. `list_project_products` — any products?
2. `get_import_logs` → `get_import_log` — did import run?
3. If `items_processed = 0` with no error → format mismatch (see `audit-errors.md`). Advise source fix / new project / support.

## D. "Prices/stock are outdated on the platform"
1. Confirm Mergado regenerated (product `output_changed_at`, project `data_updated_at`).
2. Explain the asynchronous fetch; advise "Fetch now" on the platform.

## E. Add a new output channel / comparison engine
1. `get_format` / `get_format_specification` for the target platform (also link the official spec — see `platforms.md`).
2. If the user already has a suitable project, reuse its output URL instead of creating a duplicate.
3. Otherwise `create_project` (reachable source URL) and build the required rules.

## F. Enrich / extract data (e.g. colour, GTIN)
1. Discover real elements/values with `list_project_elements` / `list_unique_element_values`.
2. `create_project_query` to target products; `query_products` to verify (mind MQL ≠ SQL and regex `\b` diacritics — see `product-queries.md`).
3. Apply the right rule; for imports from a second feed follow the destructive-import checklist in `rules-cookbook.md`.

## G. Merge two feeds
Follow the strict, destructive Data File Import checklist in `rules-cookbook.md`: inspect target → ask before `create_element` → warn about overwrites → apply after consent.
