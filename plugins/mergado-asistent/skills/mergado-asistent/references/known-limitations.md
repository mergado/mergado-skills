# Known limitations (current)

Keep this list up to date as the server changes. When a tool below fails, explain honestly and offer an alternative or the UI route — never fabricate a result.

_Verified live against the Mergado MCP server on 2026-07-10, aligned with the server's `workflow_known_limitations` on 2026-11-04. Items that can't be checked with a single call are marked (reported)._

## Silent no-ops / wrong results (looks OK but isn't — the dangerous ones)
- **Data File Import (CSV) — matching column dropped** (verified) — `file_matching_element_path` / `project_matching_element_path` come back `null`; the import then matches nothing yet returns `success`. Workaround in `rules-cookbook.md`.
- **Data File Import — upload (base64)** (verified) — silently discarded (`upload_control: null`). Use a `source_url` the user provides instead (see `rules-cookbook.md`, Data File Import).
- **Data File Import — duplicate CSV column names** (reported) — only the last column is kept; the rest is lost silently (multi-value data loss).

## Query state (fresh queries)
- A just-created query returns **`product_count: null`** (verified) and `update_query` may report a **stale** count (reported). For a reliable count use `list_project_products` with an `mql` filter and read `total_results`.
- _(The older "`query_products` returns HTTP 500 on a brand-new query" was **not reproduced** on 2026-07-10 — it returned an empty result cleanly; likely fixed.)_

## Reliability
- **Dynamic tool loading cold-start** (verified) — the first call to a lazily-loaded tool (e.g. a `create_*_rule`) can return `Unknown tool` until it loads; **retry once**. Don't confuse this with a removed tool.
- **A timeout is not a failure** (reported) — large payloads (e.g. `create_batch_rewriting_rule`) can time out while the server still applied the change; after a timeout, check with `list_project_rules` before retrying, or you risk a duplicate.
- Heavy repeated calls can **stall the server** and transient 500 / socket drops happen (reported); back off and retry.

## Data not available through the MCP backend (verified)
- **`list_project_apps` / `get_project_app`** — return empty / 404 even when an app is installed in the UI. Use `list_project_elements` / `query_products` instead.
- **Stats audits** (`list_shop_stats_audits`, `get_stats_audit`, `list_stats_audit_issues`) — return empty / 404 even when audits exist in the UI. Tell the user the MCP can't read stats audits yet; do not report their absence as "no audits".

## Behaviour & schema notes
- **`update_rule`** (verified 2026-11-04) — pauses or resumes a rule and changes its name, note, configuration or schedule. `data` and `schedule` replace the stored value as a whole, so read the rule with `get_rule` first.
- **`create_element`** succeeds but does not return the new element id (verified) — re-list with `list_project_elements`.
- **`matching_mode`** (data import) — the schema description says `exact / partial / prefix / suffix`, but the real enum is `xid / exact / contains` (verified). Use `exact` or `contains`.
- **`get_apply_logs` / `get_import_logs`** show `processed_products: 0` without a reason (reported) — check the matching column/element yourself.
- **`list_users`** may fail output validation on the `avatars` field via some clients (reported).

## Previously broken on production — now working (verified 2026-07-10)
- `list_project_rules` and `list_pairings` returned HTTP 500 on the old production build but **work on the current server**. Usable; keep an eye on them.
