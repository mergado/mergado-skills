# Element paths, MQL & regular expressions

## Element paths
An **element path** is Mergado's own notation for addressing an element — or its value / attribute — anywhere in the feed structure. Every rule's `element_path`, every variable, and every MQL condition uses it. Paths are **case-sensitive**. Never guess a path: discover real ones with `list_project_elements` and read real values with `list_unique_element_values`.

**Origin** (shown in `list_project_elements` / the UI): *input* (from the source feed), *from rule* (created/changed by a rule), *manual* (added by the user). A rule can only write to a path that exists — create the element first if it doesn't.

### Basics
- **Simple element:** `PRODUCTNAME`, `g:price`, `ITEM_ID`
- **Nesting (parent → child): pipe `|`** — `PARAM | VAL`, `g:product_detail | g:attribute_name`, `IMAGES | IMAGE`
- **Attribute: `@`** — `IMAGES | IMAGE | @description`; wrapper (product-root) attribute: `@id`
- **Condition / filter: curly braces `{ … }`** with MQL inside — `PARAM { PARAM_NAME = "Barva" } | VAL`

### Multiple (repeated) elements
Default behaviour: a rule **reads the first** matching value and **writes to all** values of a multiple element. To hit a specific one, add a condition:
- **By position — `@@POSITION`:** `IMGURL_ALTERNATIVE { @@POSITION = 2 }` (2nd value), `IMGURL_ALTERNATIVE { @@POSITION >= 2 }` (2nd onward). A non-existent position matches nothing.
- **By value — `@@VALUE`:** `IMGURL_ALTERNATIVE { @@VALUE CONTAINS "alt-3" }`, `… { @@VALUE NOT CONTAINS "alt-2" }`, `… { @@VALUE = "…" }`, `… { @@VALUE ~ "regex" }`.
- **`@@MAX_POSITION`** — helper for the highest position (count of values).
- Prefer `@@VALUE` over `@@POSITION` when the order can change.

### Nested parameter blocks (condition on a sibling/child)
Target the value inside the block whose sibling matches:
- Heureka: `PARAM { PARAM_NAME = "Barva" } | VAL`
- Google: `g:product_detail { g:attribute_name = "Řada" } | g:attribute_value`
- Shoptet: `INFORMATION_PARAMETERS | INFORMATION_PARAMETER { NAME = "Barva" } | VALUE`
- **Multiple values — `IN (...)` with `;` separator:** `PARAM { PARAM_NAME IN ("Barva";"Velikost") } | VAL`
- **Condition on an attribute:** `CATEGORIES | CATEGORY { @id = 600 }`, `IMAGES | IMAGE { @description = "…" }`
- **Combine with `AND`:** `VARIANT { CODE = "ZI1/41" AND EAN = "6655849785123" } | VISIBLE`
- **Attribute of a filtered element:** `IMAGES | IMAGE { @@VALUE ~ "alt-2" } | @description`
- **Deep multi-level nesting:** `VARIANTS | VARIANT { @id = "47" } | PARAMETERS | PARAMETER { NAME = "Barva" } | VALUE`

### Writing behaviour (important)
- Writing to a multiple element **without a condition writes to every value**; add a condition to target one.
- In a condition, parts joined with `=` / `AND` are **also created if missing** — so a targeted write can build a structured element (e.g. `FLAGS | FLAG { CODE = "action" } | ACTIVE` creates the flag if it isn't there).

### Feed cheatsheet
- **Heureka:** `IMGURL_ALTERNATIVE { @@POSITION = 2 }` · `PARAM { PARAM_NAME = "Barva" } | VAL` · `DELIVERY { DELIVERY_ID = "Česká pošta" } | DELIVERY_PRICE`
- **Google:** `g:additional_image_link { @@POSITION >= 2 }` · `g:product_detail { g:attribute_name = "Řada" } | g:attribute_value` · `g:shipping { g:country = "CZ" } | g:price`
- **Shoptet:** `IMAGES | IMAGE { @@POSITION = 2 }` · `CATEGORIES | CATEGORY { @@VALUE = "Obuv > Dětská obuv" } | @id` · `VARIANTS | VARIANT { @id = 46 } | PRICE_VAT`

Reference: https://help.mergado.com/en/mergado-editor/working-with-data/basic-components/elements-in-mergado/

## MQL — Mergado Query Language (not SQL)
Product queries use MQL, which builds on element paths. It is **not SQL** — SQL keywords/wildcards (`SELECT`, `FROM`, `WHERE`, `LIKE`, `%`, `JOIN`) do not work (`LIKE` is invalid — use `CONTAINS` or `~`).

**Syntax:** `[ELEMENT] <operator> <value>` — e.g. `[PRICE_VAT] >= 100`. Simple names without brackets also work (`PRICE_VAT >= 100`). Put values with spaces or diacritics in quotes.

**Operators**
- Comparison: `=` `!=` `<` `>` `<=` `>=` (numeric comparison works even over strings like `"433.00 CZK"`)
- Text: `CONTAINS`, `NOT CONTAINS`
- Regex: `~` (matches), `!~` (does not match)
- Sets: `IN (…)`, `NOT IN (…)` — comma-separated list, e.g. `ITEM_ID IN (101,102,103)`
- Logic: `AND`, `OR`, `NOT ( … )`
- Sorting: `SORT BY <element> ASC|DESC` (also `AS NATURAL`)

**Combining conditions** (parentheses set precedence)
- `PRICE > 1000 AND BRAND = "Nike"`
- `(PRICE > 500 AND BRAND = "Nike") OR CATEGORYTEXT CONTAINS "Sport"`
- Range: `PRICE_VAT >= 1000 AND PRICE_VAT <= 2000`
- Empty / non-empty: `g:gtin = ''` (empty), `DESCRIPTION != ''` (has any value)

**Inverse (negative) selections** — define "what NOT to touch" and negate the whole query. Build the "what I want" query, wrap it in `( )`, and prepend `NOT`:
- `ITEM_ID != 43` is the same as `NOT ( ITEM_ID = 43 )`
- `NOT ( PRODUCTNAME CONTAINS "boty" OR CATEGORY = "Doplňky" )`
- `NOT ( PRODUCTNAME CONTAINS "kalhoty" AND PRICE_VAT > 1100 )`
- `ITEM_ID NOT IN (101,102,103)`

**Regex in MQL** (via `~` / `!~`): for an exact / whole-value match, anchor with `^ … $` — e.g. `g:gtin ~ '^\d{13}$'` (exactly 13 digits). See the regex section below.

**More examples**
- `g:availability = 'in_stock' AND g:price < 500`
- `PRICE_VAT > "500" AND CATEGORYTEXT ~ "mikina" AND MANUFACTURER = "Adidas"`
- `g:title ~ '(?i)čern'` — case-insensitive match

Reference: https://help.mergado.com/en/mergado-editor/working-with-data/basic-components/operators-for-mergado-query-language/

## Regular expressions (PCRE-style)
Regex is used in **several places**, not only in MQL: the MQL operators `~` / `!~` (product queries), **variables** (extract part of a value), and **rules** such as *Find and Replace* and *Rewrite*.

### Marks
- `.` — any single character
- `*` — preceding item 0 or more times
- `+` — preceding item 1 or more times
- `?` — preceding item 0 or 1 time (optional)
- `[abc]` — one character from the set; `[^abc]` — one character NOT in the set
- `{n}` / `{n,m}` — exactly n / between n and m repetitions of the preceding item
- `^` — start of the string; `$` — end of the string
- `|` — alternation: left OR right
- `( … )` — capture group
- `\s` — whitespace (space, tab, newline); `\S` — non-whitespace
- `\d` — digit 0–9; `\D` — non-digit
- `\n`, `\r\n` — line breaks (usable in rules)
- `(?i)` — case-insensitive flag (place at the start of the pattern)

### Matching examples
- `(?i)čern` — matches "černá", "Černý", "ČERNÁ"
- `.*?(černá|bílá|červená).*` — name that contains one of these colours
- `^\d+$` — value is digits only
- `\d+(?:[.,]\d+)?` — a number with an optional decimal part

### Capture groups & references (extraction)
Wrap parts of the pattern in `( … )` to capture them, then reference a group with **backslash notation `\1`, `\2`, …** (not `$1`). References can be used in a rule's replacement field to keep only part of the match, or inside the pattern itself (`(\S+)(.*)\1` matches a group that repeats later).

### In the Find and Replace rule
Tick the **"Regular expressions"** option, put capture groups in the search pattern, and reference them in the replacement to extract/reorder text:
- **Strip HTML tags:** search `<[^>]*>` → replace with empty
- **Collapse whitespace:** search `\s{2,}` → replace with a single space
- **Swap two paragraphs:** search `^(.*?)\n\n(.*)$` → replace `\2` then `\1` (on separate lines)
- **Extract a part:** search `.*?(\d+).*` → replace `\1` writes just the first number found
Reference: https://help.mergado.com/en/mergado-editor/rules/rule-library/rule-find-and-replace/

### In variables
`create_variable` extracts a value with a `regular_expression` plus a `fragment_number` — the number of the capture group to take from the match.

### Diacritics
- The `~` regex **handles Czech diacritics reliably** (e.g. `(?i)čern`, `šed[áéý]`).
- **But `\b` (word boundary) is unreliable with Czech diacritics** — prefer explicit alternations like `.*?(černá|bílá|červená).*`.

## Gotchas from real sessions (verify, don't trust blindly)
- **Inconsistent parameter names:** `list_project_elements` / `list_project_products` take `id` (the project id), `query_products` takes `query_id`, but `create_*` tools take `project_id`. Send only the documented parameters (extra ones can crash the call).
- **`!= ""` and `NOT CONTAINS` with diacritics are unreliable**, and a **freshly populated element may return 0** until the project regenerates. Prefer `~` regex for diacritics and re-check after the rebuild. Empty-value checks (`= ""` / `!= ""`) are also **inconsistent on nested/repeated elements** — reliable mainly on flat input elements.
- **Verify a query with `query_products`** — but on a **just-created query** `product_count` comes back `null` and `update_query` may report a stale count (older builds even returned HTTP 500 until the first rebuild). For a reliable count, use `list_project_products` with an `mql` filter and read `total_results`.
- **`values_to_extract` is currently ignored** — responses return the full product tree (can be tens of thousands of tokens / hundreds of kB). Use `limit`, and if you need a single field across many products, parse the returned payload locally. See `known-limitations.md`.
- **Do not force a rebuild** (no `mark_*_dirty`); Mergado regenerates automatically, so the effect of a new query or rule appears only after the next rebuild.
