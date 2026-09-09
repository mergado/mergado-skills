# Common invalid Shoptet feed patterns and their fixes

Distilled from hundreds of real Mergado support tickets (2023–2026) + verified tests against the Shoptet validator. Ordered by frequency and impact. Each pattern: symptom → cause → fix (incl. specific Mergado rules).

---

## 1. Wrong element placement in variant products (most common)

**Symptom:** `element "VARIANTS" not allowed here`, `SHOPITEM incomplete`, `VARIANT incomplete; missing PARAMETERS`; variants break apart into standalone product cards; import pairs data incorrectly.

**Cause:** sales data (CODE/EAN/PRICE/STOCK/AVAILABILITY/VISIBLE) left at item level on a variant product; the variant parameter sits in `INFORMATION_PARAMETERS` instead of `PARAMETERS` inside `VARIANT`; `VISIBILITY`↔`VISIBLE` mix-up; or double nesting `VARIANTS>VARIANT>VARIANTS`.

**Fix:** see the complete placement map in `variant-element-placement.md` (what belongs at item level / in the variant / at both levels) and the test feed `../examples/feed-invalid-variants.xml` with isolated errors A–D.

## 2. Převodník (format converter) in Mergado destroys data (systemic pattern)

**Symptom:** only the first of multiple `CATEGORY` elements survives; `DEFAULT_CATEGORY` deleted; variant `CODE` deleted/overwritten (sometimes the whole variant structure and some products vanish); inverted `VISIBILITY` value; only the first image carried over; custom element values disappear.

**Cause:** Převodník stores data in internal Mergado XML (Universal product) and processes multiple/nested elements lossily. Documented repeatedly 2023–2026.

**Fix / prevention:**
- Between same-family formats (Kompletní (complete) ↔ Dodavatelský (supplier), CZ↔SK) **never use Převodník** — pick the same format on input and output (even "untruthfully" Kompletní when the input is Dodavatelský; the formats differ only in element scope).
- Handle currency conversion with a Výpočet (calculation) rule, not Převodník.
- Support deletes an existing Převodník in a project on request (users cannot; it is free and fast).
- If Převodník must stay: rescue data via a **helper element** (copy before the converter, restore after it) and watch rule order (rules filling custom elements must run AFTER the converter).

## 3. Number formats: prices, VAT, quantities

**Symptom:** `PRICE_VAT invalid; must be decimal with at most 2 fraction digits`, `character content of element "AMOUNT" invalid; must be a decimal number`, invalid `VAT`.

**Cause and fix:**
- `PRICE`/`PRICE_VAT`/`STANDARD_PRICE`… = max **2 decimal places**, decimal **point**. Caused by exchange-rate and margin recalculations → **Zaokrouhlit číslo** (round number) rule (to hundredths).
- `VAT` = number 0–100 with 2 decimal places, **no % sign** (e.g. `21`, not `21 %`) → Najít a nahradit (find & replace).
- `STOCK|AMOUNT` = plain number (max 3 decimal places), not text like „10 ks" → regex variable extracts the number.
- CSV imports in the Shoptet admin expect a **decimal comma** instead — do not confuse with the XML feed.

## 4. Missing required/paired elements

**Symptom:** `element "SHOPITEM" incomplete; expected ... "CODE"`, `INFORMATION_PARAMETER incomplete; missing required element "VALUE"`.

**Cause and fix:**
- Every product (and every variant) must have **CODE or EAN**. Products with neither: fill it in (e.g. from `g:Code` via Hromadné zkopírování hodnot (bulk copy values)) or hide them (query "CODE is empty" + hiding rule).
- `INFORMATION_PARAMETER` must have `NAME` and at least one `VALUE` — rules deleting only one of them produce invalid pairs. Always delete the whole pair.
- `TEXT_PROPERTY` may have only **one** `VALUE` (unlike `INFORMATION_PARAMETER`, which may have several) — merge multiple values, or use multiple TEXT_PROPERTY elements.
- Helper/working elements (CAT, IMA, …) that are not in the Shoptet spec: **hide on output** — otherwise validation reports `element ... not allowed`.

## 5. Nested structures (source of constant friction)

**Symptom:** `element "WEIGHT" not allowed here` (belongs under `LOGISTIC`); only the first image carried over; parameters "merge together".

**Rules:**
- `WEIGHT`/`WIDTH`/`HEIGHT`/`DEPTH` (logistics) belong **under `LOGISTIC`** (silent spec change 2023; Mergado 1 could not handle it, Mergado 2 can).
- Multiple elements (`IMAGES|IMAGE`, `CATEGORIES|CATEGORY`) are addressed in rules by position `{@@POSITION = n}` and fill **sequentially from the top** (position 2 cannot be filled before position 1; trick: `@@POSITION = @@MAX_POSITION + 1`).
- Copying a whole structure works only 1 nesting level deep; double nesting (e.g. `RP_IMAGES|RP_IMAGES_SK|IMAGE`) must be copied position by position.
- `STOCK|AMOUNT` is nested — fill stock there, not into a custom root-level element.

## 6. Categories

- The level separator is **`>`** (`Oblečení > Trička`), not `|` — otherwise Shoptet creates wrong categories and products import as duplicates outside the tree → Najít a nahradit `|` → `>`.
- Descriptions (`DESCRIPTION`) containing HTML tags: **wrap in CDATA** — unescaped HTML breaks validity.
- Multiple `CATEGORY` + `DEFAULT_CATEGORY`: beware of Převodník (pattern 2) and of creating both elements with duplicate identical content.

## 7. Variants: merging and limits

- Shoptet is a "variant format": variants are **nested under the master item**, not linked via ITEMGROUP_ID (that is Heureka style). Converting standalone items into variants = **Sloučení variant** (variant merging) rule (see `variant-merging.md`).
- **Max 3 variant parameters** per product (Shoptet limit; max 512 variants per product overall, limits as of 12/2025). Move the 4th and further parameters to `INFORMATION_PARAMETERS` and remove them from the variants.
- Variants of one product must have the **same name** — otherwise Shoptet applies the last variant's name to all of them. Fix by cleaning the name (regex variable, see article).
- Products under one master must have a **unique CODE per variant**; a master without its own variant plus an unreliable grouping key = breakup, or unrelated products merging together.
- The product name is partly part of the import pairing mechanism: **multiple variant products with identical names get imported under a single product**.
- Once an item imports as a variant product (even with 1 variant), it **stays variant** in the shop even on later imports without variants (data updates, structure persists).

## 8. Feed download and security (outside the XML itself)

- Shoptet feeds are usually **hash-protected** — the URL must include `?hash=…`; a Shoptet-side IP whitelist typically cannot be used. Security settings must be **saved** in the admin (common mistake).
- Misleading symptoms: `403 Forbidden`, „Zadané URL neexistuje nebo server není dostupný" (the URL does not exist or the server is unavailable), „URL neobsahuje podporovaný feed" (the URL contains no supported feed), „feed je prázdný" (the feed is empty) — the real cause is almost always the hash/security, not feed content.
- The URL must not contain unescaped characters: space = `%20`, `&` in XML as `&amp;` (otherwise `reference to entity ... must end with ';'`).
- A paused Mergado project (trial ended) redirects the output URL → Shoptet then reports `element "xml" not allowed anywhere; expected "SHOP"` — looks like a format error, but it is an inactive project.

## 9. Shoptet import behavior (not visible in the validator)

- **An empty element on import deletes the value in the shop.** Some elements should be sent even when empty; for others (e.g. `ACTION_PRICE`) the opposite holds — the sale price persists until an empty element/0 arrives.
- Supplier-import feed: **max 20 000 items** (1 item = 1 product), otherwise the feed risks deactivation.
- Product code: max **64 chars** (for Heureka preferably ≤ 36), allowed characters `A–Z 0–9 _ / -` and space.
- Images: each needs a **unique filename**; URLs without spaces (`%20`); bulk-rewriting images on existing products **adds** images, it does not delete old ones.
- Manual edits in the admin are overwritten by the next import — items/fields can be excluded from updates (the Automatický import (automatic import) feature).
- Pairing with existing items: by **code** (and for Automatický import also by EAN); the name is partly part of pairing.
- Default `VISIBILITY`: since 03/2025, items without an explicit `VISIBILITY=visible` import as **hidden** (silent Shoptet change).

## 10. Enumerated values (the validator requires them exactly)

- `ITEM_TYPE`: `product | bazaar | service | set | deposit`
- `VISIBILITY`: `visible | hidden | blocked | showRegistered | blockUnregistered | detailOnly | cashDeskOnly`
- `CURRENCY`: ISO codes per the RNG (CZK, EUR, …)
- `OSS_TAX_RATE|TAX_RATE_LEVEL`: `low | high | third | none`
- `ITEM_CONDITION|GRADE`: `open_box | used | refurbished`

---

## Meta note: the specification changes silently

Shoptet repeatedly changes the RNG without announcement (2023: `WEIGHT`→`LOGISTIC`; 03/2025: default `VISIBILITY`; 04/2026: `PURCHASE_VAT`, `PURCHASE_PRICE_INCL_VAT`, `BOX_RESTRICTION`). When the validator reports an element the bundled RNG does not know (or vice versa), download the current schemas:
https://www.shoptet.cz/export/schema/products-complete-v10.rng (supplier/datatype schemas at the same location) and trust the **live validator** at https://www.shoptet.cz/xml-validace/.
