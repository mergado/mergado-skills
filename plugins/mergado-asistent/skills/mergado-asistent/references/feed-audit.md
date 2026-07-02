# Feed audit (Product Data Audit) via the MCP

Mergado offers a **Product Data Audit** (feed quality checks, Google validators, recommended fixes). This reference covers how to use it through the MCP and its current limitations.

## Reading an existing audit (works)

- `list_project_feedaudits(project_id)` — list audits for a project.
- `get_feedaudit(id)` — audit detail (status, feed URL, feed types, parser).
- `list_feedaudit_issues(id)` → `get_feedaudit_issue(id)` — issues found.
- `list_feedaudit_products(id)` → `get_feedaudit_product(id)` → `list_feedaudit_product_issues(id)` — product-level findings.

Use these to explain concrete feed problems to the user and to drive fixes (map to `audit-errors.md`).

## Creating an audit — currently broken

- `create_feedaudit(...)` returns **HTTP 500** on the current server (with or without a valid feed URL / parser). **Do not rely on it.** If the user needs a fresh audit, direct them to the Product Data Audit in the web UI, or use an existing audit.

## Stats audits — not available via the MCP backend

- `list_shop_stats_audits` returns an empty list and `get_stats_audit` / `list_stats_audit_issues` return 404 — even when audits exist in the web UI. The data is not present in the MCP backend. **Do not present the absence as "no audits"**; if the user says they have audits, tell them the MCP cannot read stats audits yet and point them to the web UI.

## App-based audit data — unreliable

`list_project_apps` returns empty and `get_project_app` returns 404 even when an app (e.g. the Audit app) is installed in the web UI. Do not depend on the app tools for audit data; use `list_project_elements` / `query_products` for concrete checks.

## Knowledge Base

- Product Data Audit (EN): https://help.mergado.com/en/product-data-audit/
