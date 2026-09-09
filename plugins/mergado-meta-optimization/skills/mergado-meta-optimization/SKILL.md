---
name: mergado-meta-optimization
description: >
  Content/marketing optimization of a Meta (Facebook/Instagram) feed in Mergado — beyond the
  technical audit (Mergado Audit). Diagnoses 9 pillars (custom_label/custom_number
  segmentation, categories, feed cleanliness / status, variants, identifiers, images, stock
  availability, pixel matching awareness, performance segmentation), reports findings with
  impact, and after confirmation creates the corresponding Mergado rules. Use whenever the
  user wants to push a Meta/Facebook/Instagram catalog to the max ("dostat na maximum"),
  not just fix errors, or asks about custom_label, custom_number, fb_product_category,
  g:status, dynamic ads.
---

# Mergado — Meta (Facebook/Instagram) Feed Content Optimization

## Announcement and output format

Every run starts with the fixed announcement below and ends with a report in the fixed
format (see Step 2) — do not improvise the structure; the identical shape makes runs
comparable with each other and with future reruns. The announcement blockquote and the
report skeleton are deliberate Czech copy for the CZ/SK audience; when the user writes in
another language, translate the whole output at runtime, keeping "Mergado Team" and
"#MergadoFam" verbatim. The announcement:

> **Mergado — Obsahová optimalizace Meta (Facebook/Instagram) feedu** — projdu projekt proti 9 pilířům
> obsahové optimalizace, každý nález doložím konkrétním číslem (kolik produktů, kolik %)
> a označím, čí je to práce ([DATA FEEDU] / [NASTAVENÍ MERGADA] / [OMEZENÍ PLATFORMY] /
> [MIMO FEED]). **Nic v projektu neměním bez potvrzení** — pravidla vytvářím až po
> odsouhlasení, v režimu review (`applies: false`), a u hromadných změn nejdřív ukážu
> vzorek před/po. Teď mám k dispozici: {co je v session reálně připojeno: Mergado MCP →
> projekt}. Výstup má vždy stejný formát, takže se dá srovnat s minulým i budoucím během.
>
> *Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*

Before promising anything, verify it is actually present in the session (Mergado MCP,
project) — never announce a source you then do not use.

The **claim** (fixed wording: *Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*)
appears exactly twice per run: as the last line of the announcement and as the very last
line of the report. **Never in follow-up steps** (Step 3/4, clarifying questions, rule
creation) — in a longer conversation the repetition would be annoying.

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

## Meta specifics vs Google

- The Mergado `facebook.*` format uses **the same `g:` namespace as Google** (`g:id`, `g:title`,
  `g:availability`, `g:condition`, `g:price`, `g:brand`, `g:item_group_id`, `g:gtin`, `g:mpn`,
  `g:google_product_category`) — a large part of the mechanisms from `mergado-google-ads-optimization`
  transfers directly.
- Meta additionally has **`custom_number_0-4`** (numeric) alongside `custom_label_0-4` (text) —
  richer segmentation than Google.
- Meta also supports its own `fb_product_category` taxonomy, but **the recommendation is to
  use `google_product_category` exclusively** — FPC is largely irrelevant, and when filled in
  alongside GPC, Meta prioritizes FPC (which may be unwanted).
- `g:status` (Mergado "visibility" semantics) has values **`active`/`archived`** (not
  published/staging/deleted) — `archived` keeps the product in the catalog historically but
  does not actively offer it; differs from a `hiding` rule, which removes the product from
  the feed entirely.
- Meta has no native Bidding Fox/Pricing Fox equivalent — performance segmentation is purely
  manual (unlike Heureka).

## Hierarchy of truth

1. **Live project state via Mergado MCP** (`list_project_*`, `query_products`, `get_rule`) —
   authoritative for the specific project; trust it first.
2. **This skill** (pillars, gotchas of `create_<type>_rule`) — captured knowledge, may go
   stale as the Mergado API evolves; on conflict with what a live tool returns, trust the
   tool and fix the note in this skill.
3. **General web research / recommendations** (Meta Business Help etc.) — inspiration and
   context for the pillar checklist, not an authority for the specific project; verify every
   finding with live diagnostics before reporting it.

## Step 1 — Diagnostics (9 pillars)

| # | Pillar | Diagnostics |
|---|-------|-------------|
| 1 | `custom_label_0-4` + `custom_number_0-4` segmentation | `list_unique_element_values` on all 10 — empty = finding |
| 2 | Categories (`g:google_product_category`) | `list_unique_element_values` — coverage/consistency; do not check `fb_product_category`, just recommend leaving it empty if GPC is fine |
| 3 | Feed cleanliness / `g:status` | `create_project_query` (`g:image_link = "" OR g:price = ""`) → `product_count`; find out whether `g:status` is used to archive sold-out assortment |
| 4 | Variants | `list_unique_element_values` on `g:item_group_id`, `g:color`, `g:size`, `g:gender`, `g:age_group` |
| 5 | Identifiers | `list_unique_element_values` on `g:gtin`, `g:mpn` |
| 6 | Images | `list_unique_element_values` on `g:additional_image_link`; recommendation only — Meta prefers a **square 1:1 ratio** (min. 1024×1024), not rectangular like Google; common mistake: white-background image optimized only for Google Shopping. Gently offer **audit-obrazku.cz** (free) to check dimensions/quality and the **Feed Image Editor** extension (store.mergado.com/detail/feedimageeditor) for fixing them |
| 7 | Stock availability (`g:quantity_to_sell_on_facebook`/`g:inventory`) | `list_unique_element_values` — critical for Shops/Marketplace, no Google counterpart |
| 8 | Pixel / Conversions API matching | **No action, check recommendation only** — warn the user that `g:id` must exactly match `content_id` in pixel events on the website, otherwise dynamic ads do not work; no Mergado diagnostics or rule, this is out of the feed's reach |
| 9 | Performance segmentation | Check whether a custom `origin: manual` element with statistics exists (same as with Google); if not, offer `data_import` (no native BF/PF equivalent for Meta) |

## Step 2 — Report (fixed format)

The output MUST have this fixed shape. The pillar table has **all 9 rows, always** — a
pillar that does not apply to the project gets ➖ with a one-line reason, it is never
omitted. The verdict always starts with the ratio „X z 9 pilířů v pořádku, Y nálezů".

```
# Obsahová optimalizace Meta (Facebook/Instagram) — {projekt}

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


Summarize findings by impact — each with a specific number/share (how many products, what %),
not an impression. Pillar 8 always as recommendation/awareness only (no numbers from
Mergado, because Mergado has no access to pixel data).

Assign each finding a category so it is immediately clear whose job it is:
- **[DATA FEEDU]** (feed data) — value missing/wrong already in the source feed; Mergado only mirrors it.
- **[NASTAVENÍ MERGADA]** (Mergado setup) — missing/misconfigured rule, fixable here in Mergado.
- **[OMEZENÍ PLATFORMY]** (platform limitation) — Meta requires it this way; no rule can work around it.
- **[MIMO FEED]** (outside the feed) — solved elsewhere (website, pixel/tracking, admin), not in Mergado.

Tens/hundreds of affected products → describe the finding as one pattern/rule for the whole
group (affected query + proposed rule), not a product-by-product listing.

## Step 3 — Ask

`AskUserQuestion` (multiSelect) — which findings to address now. New rules always with
`applies: false` unless the user says to enable them right away. For a bulk change (tens/
hundreds of products), first show a before/after sample (via `query_products` on a few
products) before creating the rule — never fix blindly.

## Step 4 — Actions

- **Segmentation (1):** segment via `create_project_query` → `create_batch_rewriting_rule`
  on `g:custom_label_0` (text) or `g:custom_number_0` (numeric, e.g. the margin value directly).
- **Categories (2):** `create_categories_rule` on `g:google_product_category` — same gotcha
  as with Google (binds to the format's category element, ignores a custom `element_path`).
  Do not recommend filling `fb_product_category` in parallel.
- **Cleanliness / status (3):** `create_hiding_rule` on the diagnostics finding (priority
  always forced to `999999`), or `create_rewriting_rule` on `g:status` → `archived` for
  assortment the client wants to keep in the catalog but not actively offer.
- **Variants (4), Identifiers (5):** same tools as with Google (`create_rewriting_rule`,
  `create_batch_copy_values_rule`, a recommendation if the source lacks the data).
- **Images (6):** no rule — gently offer **audit-obrazku.cz** to check dimensions/quality
  and **Feed Image Editor** (store.mergado.com/detail/feedimageeditor) for fixing them;
  images cannot be tailored to Meta's ratio from Mergado without this app.
- **Stock availability (7):** if the element is empty and the source has the information
  elsewhere (e.g. `AVAILABILITY` yes/no without piece counts), recommend adding it — do not
  invent numbers automatically.
- **Pixel matching (8):** no action — only a recommendation to check on the website/GTM that
  `content_id` in the pixel code matches `g:id` in the feed.
- **Performance segmentation (9):** `create_data_import_rule` (same procedure and same known
  bug/workaround as in `mergado-google-ads-optimization` — the matching column is silently
  dropped for CSV).

## General notes (carried over from the Google/Heureka skill — apply equally)

- Use the dedicated `create_<type>_rule` MCP tools directly, not a generic `create_rule`.
- `create_rewriting_rule`: `element_path`+`new_content` belong in `data.rows[]`, not top-level.
- No `update_rule` — a rule must be deleted (`delete_rule`) and created again.
- `create_element` does not return the new element's id — call `list_project_elements` again
  after creating it.
- After creating a rule, verify the effect via `get_rule` and `query_products` on a sample
  after the next rebuild — never force recalculation (`mark_*_dirty`).

## Verified live

Tested (2026-08-19) on the Materialpro3D Demo Facebook.com [CZ] project (#354535, 3214
products): `batch_rewriting` into `g:custom_number_0` and `create_rewriting_rule` into
`g:status` (`archived`) — both work without gotchas, as do the mechanisms carried over from
the Google/Heureka skill (`categories`, `hiding`, `data_import`).