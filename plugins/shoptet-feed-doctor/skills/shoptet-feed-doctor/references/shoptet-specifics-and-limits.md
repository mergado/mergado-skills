# Shoptet: format specifics, platform behavior, and known limits

Reference for the **Shoptet Kompletní** (Complete) and **Shoptet Dodavatelský** (Supplier) formats and for platform behavior invisible in the RNG schemas and the validator. Verified in production use (2023–2026).

## Formats and official sources

- **Shoptet Dodavatelský is a subset of Kompletní** — same format family, differs only in element scope.
- Official validator: https://www.shoptet.cz/xml-validace/ (XML only, no CSV)
- RNG schemas (live, changed without notice):
  - https://www.shoptet.cz/export/schema/products-complete-v10.rng
  - https://www.shoptet.cz/export/schema/products-supplier-v10.rng
  - https://www.shoptet.cz/export/schema/products-datatype-v10.rng
- Official sample: https://www.shoptet.cz/user/documents/VariantItem.xml

## Převodník (format converter) in Mergado: avoid it

For Shoptet↔Shoptet conversions (Kompletní↔Dodavatelský, CZ↔SK) never use Převodník — it stores data through the internal Universal product and loses multiple/nested elements (categories, images, variants, custom elements).

- **Correct approach:** pick the same format for input and output (even "untruthfully" Kompletní when the input is Dodavatelský) — no Převodník gets created at all.
- Handle CZ↔SK currency with a **Výpočet** (Calculation) rule, not Převodník.
- An existing Převodník in a project is deleted on request by support (users cannot do it themselves; it is free).
- Detailed data-corruption symptoms: `common-invalid-patterns.md` §2.

## Choosing variant mode when importing into Mergado

The wizard for importing a variant feed offers:

- **A) Split into standalone items** — for advertising/price-comparison outputs (Heureka, Google…)
- **B) Keep nested variants** — for import feeds (Shoptet, Shopify…)

Choose based on the project output; for Shoptet output keep nested.

## Shoptet import behavior (not in RNG or the validator)

- **An empty element on import deletes the value in the e-shop.** For some elements this is desirable (e.g. ending a sale price — `ACTION_PRICE` persists until an empty element or 0 arrives).
- **Once variant, always variant:** an item imported with a variant structure (even a single variant) stays variant in the e-shop even after a later import without variants — data updates, structure remains. Price/stock must then be set in admin on the variant card.
- **Default visibility (silent change 03/2025):** items without an explicit `VISIBILITY=visible` import as hidden.
- **Pairing:** by code (Automatický import (Automatic import add-on) also by EAN); product name is partly involved in the pairing mechanism — multiple variant products with the same name upload as one product.
- **Bulk image overwrite appends images** after the existing ones; it does not delete old ones.
- **Manual admin edits get overwritten by the next import** — items/fields can be excluded from updates (Automatický import), typically prices after the initial upload.
- **Item missing from the feed:** with Automatický import, optionally hide / delete / leave as is.
- **Product ID from XML** usually maps to **PLU** on import.
- **Supplier import limits:** max **20 000 items** (1 item = 1 product), otherwise the feed risks deactivation; product code max **64 chars** (for Heureka prefer ≤ 36), allowed chars `A–Z 0–9 _ / -` and space; each image needs a **unique file name**.

## Admin and CSV imports (differences from XML feeds)

- **CSV imports in admin expect decimal commas** — the exact opposite of XML feeds (there RNG requires a dot). Replace values when preparing CSV.
- **FilteringProperty** accepts multiple values, separator is **`;`** (semicolon), not comma.
- **Paircode** on a product **without variants must stay empty**.
- Line breaks sometimes import from spreadsheets as `_x0000d_` — remove in Excel via Find and Replace with **CTRL+J** in the „Najít" ("Find") field.
- An empty `DESCRIPTION` can be filled with HTML `<br>` — the „Popis neexistuje" ("Description does not exist") message disappears; an image can be inserted into the description as HTML `<img>`.
- **Target URLs inside Shoptet** (links, redirects) always **relative, without domain** (`/ruzovy-slon`).

## Known platform limits (what Shoptet cannot do)

- **No order import** — only via a paid third-party add-on.
- **Two products cannot share one stock quantity** — no programmatic workaround exists.
- **Exports contain no product URL** and no language mutations (SK URL/XML). For multilingual operation, **two Shoptet stores with linked stock** is the more robust setup; articles must be created in each mutation separately.
- **Product sorting in categories** by priority = manual setup per category; by tags only with a paid add-on.
- **Heureka reviews import:** product reviews max 6 months old, shop reviews max 500 newest.
- **Second-hand goods:** can be sold (0 % VAT) but cannot be promoted e.g. on Google.
- Restricting shipping methods by order value is configured in admin (shipping type only up to a given price).

## Characters in URLs (images, links)

Shoptet does not allow spaces in URLs — encode with UTF-8 percent-encoding:

| char | code | char | code |
|---|---|---|---|
| space | `%20` | ř | `%C5%99` |
| ě | `%C4%9B` | ž | `%C5%BE` |
| š | `%C5%A1` | ý | `%C3%BD` |
| č | `%C4%8D` | á | `%C3%A1` |
| í | `%C3%AD` | é | `%C3%A9` |

Unescaped `&` in XML = invalid feed (`&` → `&amp;`).

## Silent spec changes (documented)

Shoptet changes the RNG without notice: `WEIGHT` → nested under `LOGISTIC` (2023), default `VISIBILITY` (03/2025), new elements `PURCHASE_VAT`, `PURCHASE_PRICE_INCL_VAT`, `BOX_RESTRICTION` (04/2026). When the bundled RNG schemas conflict with the live validator, trust the validator and download fresh schemas (URLs above).
