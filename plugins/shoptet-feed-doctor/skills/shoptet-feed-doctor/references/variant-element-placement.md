# Shoptet feed: element placement rules for variants

Reference map of where each element belongs in a Shoptet feed (`Shoptet kompletní` format, i.e. "Shoptet Complete") for variant products. Based on the official `VariantItem.xml` example and the RNG schemas (`products-complete-v10`), extended with findings from a real variant-import test (8/2026).

Purpose: quickly identify why a feed is invalid or why variants break apart, and where to move the element.

---

## Core principle

For a variant product, `SHOPITEM` splits into two levels:

- **item (master) level** = data shared by the whole product, directly under `<SHOPITEM>`
- **variant level** = data of a specific variant, under `<VARIANTS><VARIANT>`

Key rule (causes the most problems): once a product has variants, **sales data (code, EAN, price, stock, availability) MUST NOT stay at item level — it must move under `VARIANT`**. For a non-variant product the same elements sit directly under `SHOPITEM`.

Double nesting `VARIANTS > VARIANT > ... > VARIANTS` must never occur (produces an invalid feed; the converter breaks it destructively).

---

## 1. Item (master) level only — MUST NOT appear inside VARIANT

Descriptive and shared data of the whole product:

- `NAME`, `APPENDIX`, `SHORT_DESCRIPTION`, `DESCRIPTION`
- `MANUFACTURER`, `SUPPLIER`, `WARRANTY`, `ADULT`, `ITEM_TYPE`
- `CATEGORIES`, `IMAGES`
- `TEXT_PROPERTIES`, `INFORMATION_PARAMETERS` (descriptive/informational parameters, NOT variant-defining)
- `RELATED_PRODUCTS`, `ALTERNATIVE_PRODUCTS`, `GIFTS`
- `FLAGS`
- `HEUREKA_CATEGORY_ID`, `ZBOZI_CATEGORY_ID`, `GOOGLE_CATEGORY_ID`, `GLAMI_CATEGORY_ID`
- `VISIBILITY` (values `visible`/`hidden`)
- `RELATED_FILES`, `RELATED_VIDEOS`
- `XML_FEED_NAME`, `SEO_TITLE`, `META_KEYWORDS`, `META_DESCRIPTION`
- `ALLOWS_IPLATBA`, `ALLOWS_PAYU`, `ALLOWS_PAY_ONLINE`
- `SIZEID`, `DEPOSIT_CODE`, `DEPOSIT_LOGIC`
- `ATYPICAL_SHIPPING`, `ATYPICAL_BILLING` (standalone elements at item level)
- `INTERNAL_NOTE`, `ITEM_CONDITION`

---

## 2. Variant level only — MUST NOT stay at item level

Everything that distinguishes one variant from another:

- **Identifiers:** `CODE`, `EAN`, `EXTERNAL_CODE`, `PRODUCT_NUMBER`, `PART_NUMBER`, `SERIAL_NUMBER`, `PLU`
- **Prices:** `CURRENCY`, `PRICE`, `STANDARD_PRICE`, `PURCHASE_PRICE`, `ACTION_PRICE` (+`_FROM`/`_UNTIL`), `PRICE_RATIO`, `MIN_PRICE_RATIO`, `PRICELISTS`, `APPLY_*` discounts
- **Stock and availability:** `STOCK`, `AVAILABILITY`, `AVAILABILITY_OUT_OF_STOCK`, `AVAILABILITY_IN_STOCK`, `STOCK_MIN_SUPPLY`, `VISIBLE` (0/1), `NEGATIVE_AMOUNT`, `DECIMAL_COUNT`
- **Logistics and dimensions:** `LOGISTIC`, `DIMENSIONS`, `UNIT_OF_MEASURE`, `ATYPICAL_PRODUCT`
- **Comparison-shopping elements at variant level:** `HEUREKA_HIDDEN`, `HEUREKA_CART_HIDDEN`, `HEUREKA_CPC`, `ZBOZI_HIDDEN`, `ZBOZI_CPC`, `ZBOZI_SEARCH_CPC`, `ARUKERESO_HIDDEN`, `ARUKERESO_MARKETPLACE_HIDDEN`
- `FIRMY_CZ`, `OSS_TAX_RATES`
- **`PARAMETERS`** = variant parameters (color, size). Defines the variant itself. Max 3 variant parameters.

---

## 3. Allowed at both levels (item and variant)

- `UNIT`
- `FREE_SHIPPING`
- `FREE_BILLING`

---

## Examples

### Non-variant product
Code/price/stock directly under `SHOPITEM`:

```xml
<SHOPITEM>
  <NAME>Boty Nike AirMax</NAME>
  <CODE>DS76065630</CODE>
  <EAN>1310121350001</EAN>
  <CATEGORIES>...</CATEGORIES>
  <IMAGES>...</IMAGES>
  <STOCK>...</STOCK>
  <AVAILABILITY>Skladem</AVAILABILITY>
  <PRICE>2480.00</PRICE>
</SHOPITEM>
```

### Variant product
Shared data at the top, sales data below inside `VARIANT`:

```xml
<SHOPITEM>
  <!-- item level ONLY -->
  <NAME>Boty Nike AirMax</NAME>
  <CATEGORIES>...</CATEGORIES>
  <IMAGES>...</IMAGES>
  <INFORMATION_PARAMETERS>...</INFORMATION_PARAMETERS>
  <VISIBILITY>visible</VISIBILITY>

  <!-- both levels -->
  <UNIT>ks</UNIT>
  <FREE_SHIPPING>0</FREE_SHIPPING>

  <VARIANTS>
    <VARIANT>
      <!-- variant level ONLY -->
      <CODE>DS76065630</CODE>
      <EAN>1310121350001</EAN>
      <PRICE>2480.00</PRICE>
      <STOCK>...</STOCK>
      <AVAILABILITY>Skladem</AVAILABILITY>
      <VISIBLE>1</VISIBLE>
      <UNIT>ks</UNIT>
      <PARAMETERS>
        <PARAMETER>
          <NAME>Barva</NAME>
          <VALUE>červená</VALUE>
        </PARAMETER>
      </PARAMETERS>
    </VARIANT>
  </VARIANTS>
</SHOPITEM>
```

---

## Most common mistakes (how invalid feeds arise)

- **`VISIBILITY` vs `VISIBLE`** — easily confused. `VISIBILITY` (`visible`/`hidden`) belongs at item level, `VISIBLE` (0/1) at variant level.
- **`PARAMETERS` vs `INFORMATION_PARAMETERS`** — if a variant-defining parameter (color, size) ends up in `INFORMATION_PARAMETERS` at item level, the product splits into separate product cards or variants stop working. A variant parameter must be in `PARAMETERS` inside `VARIANT`. (Single-variant products, by contrast, may keep their parameter in `INFORMATION_PARAMETERS`.)
- **`ATYPICAL_SHIPPING`/`ATYPICAL_BILLING`** — standalone at item level, but nested inside `ATYPICAL_PRODUCT` at variant level.
- **Sales data at item level on a variant product** — `CODE`/`EAN`/`PRICE`/`STOCK` must not stay at the top, otherwise the schema fails and the Shoptet import mispairs them.
- **Double nesting `VARIANTS > VARIANT > ... > VARIANTS`** — invalid feed, destructive converter behavior (documented across support analyses 2023–2026).

---

## Shoptet validator error-message map → cause → fix

Verified with a test feed containing isolated errors (see `../examples/feed-invalid-variants.xml`) against the live Shoptet XML validator (8/2026).

**Key diagnostic point:** for the two most common errors the validator does not point at the actual culprit. The message `element "VARIANTS" not allowed here` (or `SHOPITEM incomplete`) is triggered by an element left at item level that belongs only inside a variant (sales data, `VISIBLE`, ...). Shoptet then treats the product as non-variant and rejects the `VARIANTS` block. When you see "VARIANTS not allowed here", look for the cause ABOVE, not at `VARIANTS` itself.

| Validator message (abridged) | Actual cause | Fix |
|---|---|---|
| `element "VARIANTS" not allowed here` (expected-element list lacks `CODE`/`PRICE`/`STOCK`) | Sales data (`CODE`/`EAN`/`PRICE`/`STOCK`/`AVAILABILITY`) left at item level on a variant product → product treated as non-variant | Move `CODE`/`EAN`/`PRICE`/`STOCK`/`AVAILABILITY` into each `VARIANT`; keep only shared data at item level |
| `element "VARIANT" incomplete; missing required element "PARAMETERS"` | `VARIANT` lacks the mandatory `PARAMETERS` block (the variant parameter sits elsewhere by mistake, typically in `INFORMATION_PARAMETERS` at item level) | Add the block `<PARAMETERS><PARAMETER><NAME>…</NAME><VALUE>…</VALUE></PARAMETER></PARAMETERS>` to `VARIANT` |
| `element "VARIANTS" not allowed here` (message inside `VARIANT`) | Double nesting `VARIANTS > VARIANT > VARIANTS` | Remove the nested `VARIANTS` block; a variant must not contain further variants |
| `element "VARIANTS" not allowed here` + `element "SHOPITEM" incomplete` | `VISIBLE` (0/1) is at item level → product switched to non-variant mode and `VARIANTS` rejected | `VISIBLE` belongs only inside `VARIANT`; at item level use `VISIBILITY` (`visible`/`hidden`) |
| `element "VISIBILITY" not allowed here` (inside `VARIANT`, expected list includes `PARAMETERS`) | `VISIBILITY` is inside `VARIANT` by mistake | `VISIBILITY` belongs only at item level; inside a variant use `VISIBLE` |

Schema note: the live Shoptet schema changes over time without announcement (documented silent changes: `WEIGHT` nested under `LOGISTIC` in 2023, `VISIBILITY` default behavior 03/2025, new elements `PURCHASE_VAT`, `PURCHASE_PRICE_INCL_VAT`, `BOX_RESTRICTION` 04/2026). The bundled RNG copies reflect the 08/2026 state — on any mismatch with the live validator, trust the validator and download the current RNG from shoptet.cz.

---

## Bundled sources

- `../examples/VariantItem.xml` — official Shoptet kompletní example (product without vs. with variants)
- `products-complete-v10.rng` (+ `products-supplier-v10.rng`, `products-datatype-v10.rng`) — RNG schemas for validation
- `../examples/feed-invalid-variants.xml` — test feed with isolated placement errors (control + 4 errors A–D), verified against the Shoptet validator

---

## Advanced work with variant structure in Mergado (MQL)

Verified techniques for queries and rules over nested variants. Principle: nested elements are addressed by position `{@@POSITION = n}`, and variant count is inferred from whether a given position is filled — test an element every variant always has (typically `CODE`).

### Selecting products by variant count

Products with **2 or more variants** (second position is not empty):

```
VARIANTS | VARIANT{ @@POSITION = 2 } | CODE != ""
```

Products with **exactly one variant** (first position filled, second empty):

```
VARIANTS | VARIANT{ @@POSITION = 1 } | STOCK | AMOUNT != "" AND VARIANTS | VARIANT{ @@POSITION = 2 } | STOCK | AMOUNT = ""
```

### Rewriting values at a specific variant position

Rules over variants are built per position — for each position one query + one rule with the same position:

1. Query "position n exists": `VARIANTS | VARIANT{ @@POSITION = 4 } | CODE != ""`
2. Source element: `VARIANTS | VARIANT{ @@POSITION = 4 } | PURCHASE_PRICE`
3. Rewrite target: `%VARIANTS | VARIANT { @@POSITION = 4 } | PRICELISTS | PRICELIST | PRICE_VAT%`

### Translating and transforming variant feeds

Any transformation (translation into another language, renaming) **must preserve the variant structure** — key elements (`CODE`, `NAME`, `EAN`) at the correct levels per the map above. Breaking the structure = variants falling apart on import.

### Bulk adding related files (RELATED_FILES)

Shoptet admin cannot bulk-import related files — the workaround is an import feed from Mergado (Plain CSV input). Elements are addressed:

```
RELATED_FILE|TEXT        RELATED_FILE|URL         (first file)
RELATED_FILE|1|TEXT      RELATED_FILE|1|URL       (second file, etc.)
```
