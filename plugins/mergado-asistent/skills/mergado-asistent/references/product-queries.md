# Product queries — MQL and regular expressions

## MQL — Mergado Query Language (it is NOT SQL)

Product queries use **MQL**, Mergado's own SQL-like query language. **It is not SQL.** SQL keywords and wildcards (`SELECT`, `FROM`, `WHERE`, `LIKE`, `%`, `JOIN`, …) do **not** work and will fail. Use only the documented MQL operators — never invent operators.

**Syntax:** `[ELEMENT] <operator> <value>` — e.g. `[PRICE_VAT] >= 100`. Combine conditions with `AND` / `OR`.
(Simple element names without brackets also work through the MCP, e.g. `PRICE_VAT >= 100`, but the documented bracket form is canonical.)

**Operators:**
- Comparison: `=`, `!=`, `<`, `>`, `<=`, `>=`
- Text: `CONTAINS`, `NOT CONTAINS`
- Regular expression: `~` (matches), `!~` (does not match)
- Sets: `IN`, `NOT IN`
- Logic: `AND`, `OR`
- Sorting: `SORT BY <element> ASC|DESC` (also `AS NATURAL`)

**Examples:**
- `PRICE_VAT >= 100 AND PRICE_VAT < 500`
- `g:gtin = '' ` (products with an empty GTIN)
- `PRODUCT ~ '.*?(black|white|red).*'` (name contains a colour)

Canonical reference (link it, do not invent):
- EN: https://help.mergado.com/en/mergado-editor/working-with-data/basic-components/operators-for-mergado-query-language/
- CS: https://help.mergado.com/cs/mergado-editor/prace-s-daty/zakladni-prvky/operatory-pro-mergado-query-language/

## Regular expressions (Mergado-specific)

- Regex is used via the MQL `~` / `!~` operators and inside Rewrite / Find-and-Replace rules. The flavor is **PCRE-style**.
- Basic marks: `.` `*` `?` `+` `[]` `{}` `^` `$` `|` `\s` `\d` `\S` `\D`.
  Overview (in Czech): https://forum.mergado.cz/t/zakladni-prehled-znacek-pro-regularni-vyrazy/1144
- **Word boundary `\b` is unreliable with Czech diacritics** (á, č, ř…). Prefer explicit alternations such as `.*?(černá|bílá|červená).*` instead of relying on `\b`.
- **Always test a regex query with `query_products`** before building a rule on top of it (proactive verification).

## Input vs. output element names

The output name `PRODUCTNAME` often does **not** exist on the input — it is built by rules. When you build a query over **input** data, match the original element (commonly `PRODUCT` or `NAME_EXACT`), not `PRODUCTNAME`.

## Creating and checking queries via MCP

- Create: `create_project_query(project_id, name, query)`.
- Verify: `query_products(query_id)` — confirm the query returns the products you expect.
- Assign to a rule: `assign_query_to_rule(rule_id, query_id)`; inspect with `list_rule_queries`.
- Manage: `get_query`, `update_query`, `delete_query`, `list_project_queries`.
