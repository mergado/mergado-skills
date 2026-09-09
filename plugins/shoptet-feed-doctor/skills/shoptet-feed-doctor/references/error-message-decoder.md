# Error Message Decoder (Shoptet validator + Mergado)

The official Shoptet validator (https://www.shoptet.cz/xml-validace/) works as a black box over RNG — its messages are often misleading and do not point at the real culprit. This decoder maps message → real cause → fix. Verified with a test feed containing isolated errors (`../examples/feed-invalid-variants.xml`) and hundreds of real support cases.

**Golden rule:** the validator validates against RNG "outside-in". When it rejects a `VARIANTS` block, the error is almost always HIGHER UP (an element left at item level that does not belong there) — not inside `VARIANTS` itself.

---

## A. Shoptet validator messages (RNG)

| Message (abridged) | Real cause | Fix |
|---|---|---|
| `element "VARIANTS" not allowed here` (CODE/PRICE/STOCK missing from the expected list) | Selling data (CODE/EAN/PRICE/STOCK/AVAILABILITY) left at item level on a variant product → the "non-variant" RNG branch is already taken and VARIANTS has nowhere to fit | Move selling data into every `VARIANT`; keep only shared data on the item |
| `element "VARIANTS" not allowed here` + `element "SHOPITEM" incomplete` | `VISIBLE` (0/1) at item level → the product slipped into the non-variant branch | `VISIBLE` only inside `VARIANT`; put `VISIBILITY` (visible/hidden) on the item |
| `element "VARIANT" incomplete; missing required element "PARAMETERS"` | Variant is missing the required `PARAMETERS` block (the variant parameter mistakenly sits in `INFORMATION_PARAMETERS` on the item) | Add `PARAMETERS > PARAMETER > NAME + VALUE` to every `VARIANT` |
| `element "VARIANTS" not allowed here` (inside `VARIANT`) | Double nesting `VARIANTS > VARIANT > VARIANTS` | Remove the nested block; a variant must not contain variants |
| `element "VISIBILITY" not allowed here` (`PARAMETERS` expected) | `VISIBILITY` mistakenly inside `VARIANT` | `VISIBILITY` on the item; `VISIBLE` in the variant |
| `element "SHOPITEM" incomplete; expected ... "CODE"` | Product/variant has neither `CODE` nor `EAN` (often a single product without EAN in the whole feed) | Add CODE/EAN, or hide the product (query "CODE is empty") |
| `element "WEIGHT" not allowed here` | Weight is in the old position — since 2023 it belongs nested under `LOGISTIC` | Move to `LOGISTIC > WEIGHT` (Mergado 2; M1 could not do this) |
| `INFORMATION_PARAMETER incomplete; missing required element "VALUE"` | A rule deleted VALUE but kept NAME (or vice versa) | Always delete/fill the whole NAME+VALUE pair |
| `character content of element "AMOUNT" invalid; must be a decimal number` | `STOCK\|AMOUNT` contains text („10 ks") or a number with a comma | Extract a clean number with regex; decimal point |
| `PRICE_VAT invalid; ... at most 2 fraction digits` (typically hundreds of occurrences) | Currency/margin recalculation produced more than 2 decimal places | Rule Zaokrouhlit číslo (Round number) to hundredths on PRICE_VAT/PRICE |
| Invalid `VAT` | `%` character in the value, or decimals | VAT = plain number 0–100 (`21`) |
| `element "xml" not allowed anywhere; expected element "SHOP"` | The URL is not a product feed: a paused Mergado project (trial ended) redirected the output, or a different XML document sits there | Check project status/payment; verify the URL is the output feed, not the input |
| `Content is not allowed in prolog` / `element "html" not allowed; expected "SHOP"` | Foreign content got in front of `<SHOP>` — an HTML error page, unhidden input elements, BOM | Hide foreign elements on the output; verify the URL returns clean XML |
| `reference to entity "..." must end with ';'` | Unescaped `&` in a URL/text | `&` → `&amp;` (typically in feed URL parameters) |
| `element "..." not allowed` (custom/helper element) | Helper elements (CAT, IMA, custom) do not belong to the Shoptet specification | Hide them on the output |
| Validator "finds nothing", but Shoptet import reports errors | The validator handles only XML (Shoptet complete/supplier), not CSV; import additionally checks things beyond RNG (duplicate codes, variant names, limits) | Check patterns 7 and 9 in `common-invalid-patterns.md`; request the error from Shoptet's import log |
| Feed is valid, but images/products do not show in Shoptet | Problem beyond the feed's boundary: image URLs return 404 (supplier), admin settings, limits | Verify a sample of image URLs; Shoptet support handles the rest |

## A2. Local validation messages (`scripts/validate.py` — lxml/libxml2)

The local validator speaks a different dialect than the web validator (Jing) — same errors, different
words. Mapping verified on `../examples/feed-invalid-variants.xml` and isolated tests:

| lxml/libxml2 message | Real cause | Section A equivalent |
|---|---|---|
| `Extra element VARIANTS in interleave` | Selling data (CODE/EAN/PRICE/STOCK/AVAILABILITY) or `VISIBLE` left at item level → the non-variant RNG branch is taken and `VARIANTS` has nowhere to fit | `element "VARIANTS" not allowed here` |
| `Extra element <X> in interleave` (X = PRICE_VAT, VAT, STOCK…) | **Beware, trap:** often NOT a structural error but an invalid VALUE of element X (more than 2 decimal places, `%` in VAT, text in AMOUNT). libxml2 drops an element with a bad value and reports it as "extra" | `PRICE_VAT invalid; at most 2 fraction digits` / `AMOUNT must be a decimal number` |
| `Expecting element VARIANTS, got CODE` (on a non-variant product) | False lead — accompanies the previous error: the non-variant branch failed (due to a bad value/element), the validator tried the variant branch, which of course did not fit | — (ignore, fix the primary error) |
| `Expecting element VARIANTS, got VISIBLE` | `VISIBLE` (0/1) at item level instead of `VISIBILITY` (visible/hidden) | `element "VARIANTS" not allowed here` + `SHOPITEM incomplete` |
| `Expecting an element PARAMETERS, got nothing` | Variant is missing the required `PARAMETERS` block | `element "VARIANT" incomplete; missing required element "PARAMETERS"` |
| `Expecting an element CODE, got nothing` | Product/variant has neither `CODE` nor `EAN` | `element "SHOPITEM" incomplete; expected ... "CODE"` |
| `Element VARIANT has extra content: VARIANTS` | Double nesting `VARIANTS > VARIANT > VARIANTS` | `element "VARIANTS" not allowed here` (inside VARIANT) |
| `Element SHOPITEM has extra content: <X>` | Custom/helper element X does not belong to the Shoptet specification | `element "..." not allowed` |
| `Element SHOPITEM/VARIANT/VARIANTS failed to validate content`, `Invalid sequence in interleave` | Wrapper messages — say nothing by themselves, but **carry the culprit's line number** | — |

**Reading the output:** `Extra element … in interleave` messages come with `line 0` (no line number).
Find the actual item in the accompanying `Element SHOPITEM failed to validate content` message,
which does point to a line. Procedure: (1) take the line from `SHOPITEM failed to validate`, (2) associate
the surrounding "extra/expecting" messages with it, (3) interpret using the table — and for "extra element"
always check the element's VALUE too, not just its position.

## B. Mergado messages when downloading/processing a feed

| Message / symptom | Real cause | Fix |
|---|---|---|
| `403 Forbidden`, „feed je prázdný" (feed is empty) | The Shoptet feed is protected (hash/access restriction) | Append `?hash=…` to the URL per the security settings in the Shoptet admin; SAVE the settings |
| „Zadané URL neexistuje nebo server není dostupný" (the URL does not exist or the server is unavailable) | Most often a protected feed again; sometimes a genuinely dead supplier server or an unlaunched e-shop | Hash first; only then troubleshoot server availability |
| „URL neobsahuje podporovaný feed" (the URL does not contain a supported feed) | Protection, or the URL does not lead to XML/CSV/JSON (e.g. a SOAP/API endpoint) | Hash; verify it is a real feed |
| Timeout / „vypršel časový limit" (time limit expired) | Large feed, slow supplier server, bot blocking | Shrink the feed, whitelist Mergado's IP (81.31.39.112) on the source side, resolve with the provider |
| „Nenalezeny žádné produkty" (no products found) on the output | (a) enabled Autorizace produktů (product authorization) is waiting for approval, (b) „Přegenerovat změněné" (regenerate changed) instead of "all", (c) wrong input format | (a) approve/disable authorization, (b) „Přegenerovat vše" (regenerate all), (c) fix the input format |
| Input has N products, output has far fewer | Input format "variants as standalone items" vs. output merging variants into 1 product — counts legitimately differ | Not an error; optionally choose a different variant mode on import |
| A rule "does not apply" | Rule order (a query relies on data created later; another rule overwrites the result), typographic quotes in the condition (`´2´` vs `"2"`) | Reorder rules; unify quotes; base queries on input data |
| Rules broke after changing the input format | Queries/elements no longer match the new structure | Review the rules and disable/remap them |

## C. Diagnostic procedure (recommended order)

1. **Does the feed download at all?** (section B: hash, 403, timeout)
2. **Is it XML with a `<SHOP>` root?** (prolog, html, xml-expected-SHOP)
3. **Local RNG validation** against `products-complete-v10.rng` (see `SKILL.md` — scripts/validate.py) — gives a more precise and complete report than the web validator.
4. **Interpret the messages** per section A — beware "the culprit is one level up" („viník je výš") with variants.
5. **Verify with the official Shoptet validator** (authoritative, but a black box).
6. **Checks beyond RNG:** duplicate codes, identical variant names, limits (20,000 items, 3 variant parameters, 512 variants), empty vs. missing elements, import behavior (patterns 7–9 in `common-invalid-patterns.md`).
