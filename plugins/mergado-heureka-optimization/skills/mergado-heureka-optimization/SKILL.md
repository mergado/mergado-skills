---
name: mergado-heureka-optimization
description: >
  Content/marketing optimization of a Heureka feed in Mergado — beyond the technical audit
  (Mergado Audit). Diagnoses 9 pillars (product pairing, CPC/bidding segmentation, feed
  cleanliness, delivery, variants, conversion extra elements, ITEM_TYPE, images,
  performance/repricing), reports findings with impact, and after approval creates the
  corresponding Mergado rules. Use whenever the user wants to push a Heureka feed to the
  max ("dostat na maximum"), not just fix errors, or asks about product pairing,
  HEUREKA_CPC, GIFT/ACCESSORY/EXTENDED_WARRANTY, ITEM_TYPE.
---

# Mergado — Heureka Feed Content Optimization

## Announcement and output format

Every run starts with the fixed announcement below and ends with the fixed-format report
(see Step 2) — do not improvise the structure; the identical shape makes runs comparable
with each other and with future reruns. The announcement blockquote and the Step 2 report
skeleton are deliberate Czech copy for the CZ/SK audience — when the user writes in
another language, translate the whole output at runtime, keeping "Mergado Team" and
"#MergadoFam" verbatim:

> **Mergado — Obsahová optimalizace Heureka feedu** — projdu projekt proti 9 pilířům
> obsahové optimalizace, každý nález doložím konkrétním číslem (kolik produktů, kolik %)
> a označím, čí je to práce ([DATA FEEDU] / [NASTAVENÍ MERGADA] / [OMEZENÍ PLATFORMY] /
> [MIMO FEED]). **Nic v projektu neměním bez potvrzení** — pravidla vytvářím až po
> odsouhlasení, v režimu review (`applies: false`), a u hromadných změn nejdřív ukážu
> vzorek před/po. Teď mám k dispozici: {co je v session reálně připojeno: Mergado MCP →
> projekt}. Výstup má vždy stejný formát, takže se dá srovnat s minulým i budoucím během.
>
> *Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*

Before promising anything, verify it is actually present in the session (Mergado MCP,
project) — never announce a source you will not end up using.

**Claim** (fixed wording: *Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*)
appears exactly twice per run: as the last line of the announcement and as the very last
line of the report. **Never in follow-up steps** (Step 3/4, clarifying questions, rule
creation) — repeating it in a longer conversation would be annoying.

## Prerequisite — Mergado Audit

This skill builds on **Mergado Audit**, Mergado's technical feed check
(<https://help.mergado.com/cs/audit-produktovych-dat/>). Content optimization layered on a
technically broken feed is wasted work, so establish the technical baseline first — but
**never block on it**.

When the Mergado MCP is connected, run the audit through it rather than sending the user
elsewhere: it exposes tools for listing existing audits, starting a new one, following it to
completion and reading its findings. Take the arguments and the sequencing from those tools'
own descriptions — they are authoritative and current, this file is not. One thing worth
insisting on: tell the audit which channel format to judge the feed against instead of letting
it guess. The guess is structural, and a feed judged by the wrong rulebook produces confident
findings that answer a different question than the user asked.

Report the audit as the technical baseline, then continue with the pillars below. If it cannot
run — no MCP, no write access, or the audit fails — say so in one line and carry on; the
pillars do not depend on it.

## Heureka specifics vs Google

- **Product pairing** (CATEGORYTEXT + PRODUCTNAME + EAN) is itself a key performance
  factor, not just technical validity — an unpaired product shows up only in fulltext search.
- **Bidding (HEUREKA_CPC) is a feed element directly**, not an external platform like Google Ads.
- Heureka has native Mergado extensions for automation: **Bidding Fox** (automatic
  performance-based bidding) and **Pricing Fox** (competitor-based repricing) — these are
  not rules this skill creates, only recommendations with a link to store.mergado.com.

## Hierarchy of truth

1. **Live project state via Mergado MCP** (`list_project_*`, `query_products`, `get_rule`) —
   authoritative for the specific project; trust it first.
2. **This skill** (pillars, gotchas for `create_<type>_rule`) — snapshotted knowledge that
   can go stale as the Mergado API evolves; on conflict with what a live tool returns,
   trust the tool and fix the note in the skill.
3. **General web research / recommendations** (help.mergado.com, sluzby.heureka.cz) —
   inspiration and context for the pillar checklist, not an authority for the specific
   project; verify every finding with live diagnostics before reporting it.

## Step 1 — Diagnostics (9 pillars)

| # | Pillar | Diagnostics |
|---|-------|-------------|
| 1 | Pairing (CATEGORYTEXT/PRODUCTNAME/EAN) | **Sample only** (e.g. 10-20 products via `query_products`, not the whole feed — saves tokens) — check that `CATEGORYTEXT` has more than 1 level (contains `\|`) and that `PRODUCTNAME` contains the brand |
| 2 | `HEUREKA_CPC` segmentation | `list_unique_element_values` — empty/uniform for all products = finding |
| 3 | Feed cleanliness | `create_project_query` (`DELIVERY_DATE > 30 OR URL = "" OR EAN = ""` for mandatory categories) → `product_count` |
| 4 | Delivery (`DELIVERY`) | `list_project_elements` — how many carriers are set; `list_unique_element_values` on `DELIVERY_PRICE` |
| 5 | Variants (`ITEMGROUP_ID`) | `list_unique_element_values` — empty for products that have variants (same name stem) |
| 6 | Conversion extra elements (GIFT, ACCESSORY, EXTENDED_WARRANTY, SPECIAL_SERVICE, SALES_VOUCHER) | `list_project_elements` — do they exist in the project? If not, check whether the **input** feed has an equivalent source element they could be filled from (no point recommending it if the client has no data) |
| 7 | `ITEM_TYPE` | `list_unique_element_values` — empty for all = finding only if the shop actually sells second-hand/refurbished goods (ask before acting on it) |
| 8 | Images (`IMGURL`) | Recommendation only — offer **audit-obrazku.cz** (free) to check dimensions/watermarks, and the **Feed Image Editor** extension (store.mergado.com/detail/feedimageeditor) for fixing/editing |
| 9 | Performance segmentation / repricing | Check whether **Mergado Keychain** is connected to Heureka (`list_project_elements` — look for statistics); if not, offer as a tip **Bidding Fox** (store.mergado.com/detail/biddingfox) for automatic bidding and **Pricing Fox** (store.mergado.com/detail/pricingfox) for competitor-based repricing — gently, as a recommendation with a link, not a forced action |

## Step 2 — Report (fixed format)

The output MUST have this fixed shape. The pillar table always has **all 9 rows** — a
pillar that does not apply to the project gets ➖ with a one-line reason, never omitted.
The verdict always starts with the ratio "X z 9 pilířů v pořádku, Y nálezů".

```
# Obsahová optimalizace Heureka — {projekt}

## Vstup a metoda
| | |
|---|---|
| Projekt | {název, id} |
| Výstupní formát | {output_format} |
| Produktů | {exported_items} |
| Poslední sync | {data_synced_at — starší než 7 dní zaslouží poznámku} |
| Datum | {datum} |

**Legenda:** ✅ v pořádku / využito · ⚠️ nevyužitá příležitost · ❌ reálně omezuje výkon ·
➖ netýká se tohoto projektu · ℹ️ jen doporučení nástroje/postupu

## Verdikt
{X} z 9 pilířů v pořádku, {Y} nálezů — největší dopad má {pilíř} ({číslo/podíl}).

## Nálezy podle pilířů (vždy všech 9)
| # | Pilíř | Stav | Nález (vždy konkrétní číslo/podíl) | Kategorie |
|---|---|---|---|---|
| 1–9 | {názvy pilířů dle Kroku 1} | ✅/⚠️/❌/➖/ℹ️ | {…} | {[DATA FEEDU] apod.} |

{U ⚠️/❌ nálezů pod tabulkou krátký blok: dotčená query + navrhované pravidlo — jeden
vzorec pro celou skupinu, ne výčet produktů.}

## Doporučený postup (max 5, jedna věta, podle dopadu)
1. {…}

## Co jsme NEmohli ověřit
{vzorek vs. celý katalog; co by odemklo připojení dalšího zdroje; pixel/web mimo Mergado}

---

Které nálezy mám rozpracovat, nebo rovnou řešit? Pravidla založím až po vašem potvrzení,
v režimu review. Napište čísla pilířů, nebo „všechny".

*Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*
```


Summarize findings by impact — each with a concrete number/share (how many products, what
%), not an impression. Pillars 8 and 9 are purely tool recommendations (FIE, BF, PF) — do
not present them as a "problem" but as "this could help you further".

Assign a category to each finding so it is immediately clear whose job it is:
- **[DATA FEEDU]** — value missing/wrong already in the source feed; Mergado only mirrors it.
- **[NASTAVENÍ MERGADA]** — rule missing/misconfigured; fixable right here in Mergado.
- **[OMEZENÍ PLATFORMY]** — Heureka requires it this way; no rule can work around it.
- **[MIMO FEED]** — solved elsewhere (website, admin, an app like Bidding Fox), not in Mergado.

Tens/hundreds of affected products → describe the finding as one pattern/rule for the
whole group (affected query + proposed rule), not a product-by-product listing.

## Step 3 — Ask

`AskUserQuestion` (multiSelect) — which findings to address now. New rules always with
`applies: false` unless the user says to enable them right away. For a bulk change (tens/
hundreds of products), first show a before/after sample (via `query_products` on a few
products) before creating the rule — never fix blindly.

## Step 4 — Actions

- **Pairing (1):** `create_categories_rule` on `CATEGORYTEXT` (mapping to Heureka's
  category tree — same gotcha as with Google: it binds to the format's category element).
  For `PRODUCTNAME` missing a brand/parameter: `create_rewriting_rule` with a dynamic
  reference (`%PRODUCTNAME% %PARAM{PARAM_NAME="VELIKOST"} | VAL%`).
- **CPC segmentation (2):** segment via `create_project_query` (price tiers/margins) →
  `create_batch_rewriting_rule` on `HEUREKA_CPC`, or `create_batch_rewriting_values_rule`
  by `CATEGORYTEXT`/`MANUFACTURER`. **Tip for the user:** for automatic bidding without
  manual setup, offer Bidding Fox.
- **Cleanliness (3):** `create_hiding_rule` on the query from diagnostics (note: priority
  is always forced to `999999`).
- **Delivery (4):** `create_batch_delivery_rule` (carriers allowed by Heureka, prices by
  price tier or weight). Never use carriers other than those Heureka allows in its
  specification.
- **Variants (5):** filling in `ITEMGROUP_ID` — if the source has a shared variant code
  elsewhere, `create_rewriting_rule`/`create_batch_copy_values_rule`; otherwise recommendation only.
- **Extra elements (6):** if the element does not exist and the source has the data,
  `create_element` (**ask the user before creating it** — extra new structure) → `create_rewriting_rule`
  on the nested path (verified live, e.g. `element_path: "EXTENDED_WARRANTY | VAL"`) or `create_batch_param_rule`
  depending on the target element's structure. Before creating the rule, verify the exact
  element path via `list_project_elements` — nesting differs element by element (`GIFT`
  has an `ID` attribute, `EXTENDED_WARRANTY` has `VAL`+`DESC`, `SALES_VOUCHER` has `CODE`+`DESC`).
  ⚠️ **`create_rewriting_rule` gotcha:** `element_path` and `new_content` belong in `data.rows[]`
  (`{"rows": [{"element_path": "...", "new_content": "..."}]}`), not as top-level parameters
  next to `data` — a top-level `new_content` returns "Additional properties are not allowed".
- **ITEM_TYPE (7):** `create_batch_rewriting_values_rule` (mapping of the source
  goods-type flag → Heureka value, e.g. `bazar`).
- **Images (8), Performance/repricing (9):** no rule — recommendation only, with links to
  audit-obrazku.cz / store.mergado.com (FIE, Bidding Fox, Pricing Fox).

## General notes (carried over from verification on the Google skill — apply equally)

- Use the dedicated `create_<type>_rule` MCP tools directly, not a generic `create_rule`.
- No `update_rule` — a rule must be deleted (`delete_rule`) and created anew.
- `create_element` does not return the new element's id — call `list_project_elements` again after creating.
- After creating a rule, verify the effect via `get_rule` and `query_products` on a sample
  after the next rebuild — never force a recalculation (`mark_*_dirty`).