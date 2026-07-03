# MCP recipes — call sequences

Recipes are sequences, not dogma; improvise within the guardrails in `SKILL.md`.

## Foundation: navigation chain

`get_current_user` → `list_user_eshops(user_id)` → `list_shop_projects(shop_id)` → project tools.
`get_current_user` is reliable — use it. `list_users` returns only users who share an e-shop with the current identity.

## Guardrails (repeat of SKILL.md, because they matter here)

- **Do not** call `mark_query_products_dirty`, `mark_project_products_dirty`, or `update_project(is_dirty=true)`. Regeneration is automatic.
- **Do not** read raw XML; use `list_project_elements`, `list_unique_element_values`, `query_products`, `get_product`.
- **Verify** queries/rules with `query_products`.
- Rules need real `element_path`, numeric `priority`, `queries=[{"id":…}]`, and `applies:true` to take effect. No `update_rule` exists.

## Recipe: feed diagnostics

1. `list_project_products(project_id, limit=…)` — is there data at all?
2. `get_import_logs(project_id)` → `get_import_log(log_id)` — did import run and succeed?
3. `get_apply_logs`, `get_export_logs` — where does the chain break?

## Recipe: zero imported products

`get_import_logs` / `get_import_log`. If it does **not** error but `items_processed = 0`, it is usually a **format mismatch** — the project expects one root element (e.g. `<SHOPITEM>`, Heureka) but the source sends another (e.g. `<ITEM>`, Mergado). The input format of an existing project cannot be changed by the user → advise fixing the source, a new project, or support.

## Recipe: new output channel

1. `get_format(slug)` / `get_format_specification(slug)` — what does the platform require?
2. If a new project is needed: `create_project(shop_id, name, url, input_format, output_format)` — the source URL must be reachable (Mergado validates it).
3. Build rules for missing required elements.
Avoid duplicates: if a Google project already exists, tell the user to copy its **output feed URL** into GMC instead of creating a new project.

## Recipe: value enrichment / extraction

1. `list_project_elements` and `list_unique_element_values` — discover real element names and values (never read the raw feed).
2. `create_project_query` to target the affected products; `query_products` to verify.
3. Apply with the appropriate `create_*_rule` (see `rules-cookbook.md`). Remember MQL ≠ SQL and the regex caveats (`product-queries.md`).

## Recipe: rule inspection

`list_project_rules` → `get_rule` → `list_rule_queries` → `query_products` for real examples. To replace a broken rule, `delete_rule` the old one (no pause/`update_rule`).

## Recipe: audit trail

Read chronologically: `get_import_logs`, `get_apply_logs`, `get_export_logs`, `get_access_logs` (+ their single-item `get_*_log`).

## Known issues (current MCP)

- `create_rounding_rule` → HTTP 500 (Round Numbers is broken).
- `create_feedaudit` → HTTP 500 (creating a new audit fails; reading existing audits works).
- `mark_project_products_dirty` → HTTP 599 timeout (another reason not to use dirty tools).
- `list_project_apps` / `get_project_app` and the stats-audit tools return empty/404 (data not present in the MCP backend even when visible in the web UI) — do not rely on them.
- `list_users` output may fail schema validation on the `avatars` field via the MCP wrapper.
- `create_element` succeeds but does not return the new element id.
When a tool fails, explain honestly and offer an alternative or the UI route — never fabricate a result.
