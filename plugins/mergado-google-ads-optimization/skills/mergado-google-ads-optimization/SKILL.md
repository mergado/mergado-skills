---
name: mergado-google-ads-optimization
description: >
  Content/marketing optimization of a Google Shopping feed in Mergado — beyond the technical
  audit (Mergado Audit). Diagnoses 9 pillars (segmentation, categories, feed cleanliness,
  title/description quality, identifiers, variants, images, shipping, performance segmentation),
  reports findings with impact, and after user approval creates the corresponding Mergado
  rules. Use whenever the user wants to push their Google Shopping/GMC feed to the max
  ("dostat na maximum"), not just fix errors, or asks about custom_label, segmentation,
  category mapping, GTIN/MPN coverage.
---

# Mergado — Google Feed Content Optimization

## Announcement and output format

Every run starts with the fixed announcement below and ends with a fixed-format report
(see Step 2) — do not improvise the structure; the identical shape makes runs comparable
with each other and with future reruns. The announcement blockquote and the report
skeleton in Step 2 are deliberate Czech copy for the CZ/SK audience — when the user
writes in another language, translate the whole output at runtime, keeping "Mergado Team"
and "#MergadoFam" verbatim. The announcement:

> **Mergado — Obsahová optimalizace Google Shopping feedu** — projdu projekt proti 9 pilířům
> obsahové optimalizace, každý nález doložím konkrétním číslem (kolik produktů, kolik %)
> a označím, čí je to práce ([DATA FEEDU] / [NASTAVENÍ MERGADA] / [OMEZENÍ PLATFORMY] /
> [MIMO FEED]). **Nic v projektu neměním bez potvrzení** — pravidla vytvářím až po
> odsouhlasení, v režimu review (`applies: false`), a u hromadných změn nejdřív ukážu
> vzorek před/po. Teď mám k dispozici: {co je v session reálně připojeno: Mergado MCP →
> projekt}. Výstup má vždy stejný formát, takže se dá srovnat s minulým i budoucím během.
>
> *Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*

Before promising anything, verify it is actually present in the session (Mergado MCP,
project) — never announce a source you will not use.

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

## Hierarchy of truth

1. **Live project state via Mergado MCP** (`list_project_*`, `query_products`, `get_rule`) —
   authoritative for the specific project; trust it first.
2. **This skill** (pillars, gotchas for `create_<type>_rule`) — snapshot knowledge that can
   go stale as the Mergado API evolves; on conflict with what a live tool returns, trust
   the tool and fix the note in the skill.
3. **General web research / recommendations** (Google Merchant Center Help etc.) —
   inspiration and context for the pillar checklist, not an authority for the specific
   project; verify every finding with live diagnostics before reporting it.

## Step 1 — Diagnostics (9 pillars)

Element paths with nested elements use `|`, not `/` (e.g. `g:shipping | g:price`,
`Stats | ROAS`).

| # | Pillar | Diagnostics |
|---|-------|-------------|
| 1 | Segmentation `custom_label_0-4` | `list_unique_element_values` on each; empty = finding |
| 2 | Category / `product_type` mapping | `list_unique_element_values` on `g:google_product_category` and `g:product_type` — compare coverage and consistency |
| 3 | Feed cleanliness | `create_project_query` (`g:image_link = "" OR g:price = ""`) → check `product_count` |
| 4 | Title/description quality | `query_products` on a sample — `g:description` length, promo words in `g:title` |
| 5 | GTIN/MPN coverage | `list_unique_element_values` on `g:gtin`, `g:mpn` — compare `total_results` with the project's product count |
| 6 | Variants | `list_unique_element_values` on `g:item_group_id`, `g:color`, `g:size` |
| 7 | Images | `list_unique_element_values` on `g:additional_image_link` |
| 8 | Shipping | `list_unique_element_values` on `g:shipping \| g:price` |
| 9 | Performance segmentation | `list_project_elements` — look for a custom `origin: manual` element with stats (clicks/cost/conversion/revenue); if it exists, check via `list_unique_element_values` whether it holds real data or is empty |

Verified live (2026-08) on two real projects — the mechanism works, findings are real
(e.g. `custom_label` almost never used, `MPN` often missing even when `GTIN` is OK).

## Step 2 — Report (fixed format)

The output MUST have this fixed shape. The pillar table **always has all 9 rows** — a
pillar that does not apply to the project gets ➖ with a one-line reason, never omitted.
The verdict always starts with the ratio "X z 9 pilířů v pořádku, Y nálezů".

```
# Obsahová optimalizace Google Shopping — {projekt}

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


Summarize findings sorted by impact (how many products / what %), including pillars that
are already fine (don't spend time on what needs no action). For every finding cite a
concrete number/share (how many products, what %), not an impression ("a lot", "almost none").

Assign each finding a category so it is immediately clear whose job it is:
- **[DATA FEEDU]** — value missing/wrong already in the source feed; Mergado only mirrors it.
- **[NASTAVENÍ MERGADA]** — missing/misconfigured rule; fixable right here in Mergado.
- **[OMEZENÍ PLATFORMY]** — Google requires it this way; no rule can work around it.
- **[MIMO FEED]** — solved elsewhere (website, pixel/tracking, admin), not in Mergado.

Tens/hundreds of affected products → describe the finding as one pattern/rule for the
whole group (affected query + proposed rule), not a product-by-product list.

## Step 3 — Ask

Use `AskUserQuestion` (multiSelect) to ask which findings the user wants addressed now.
Always create new rules with `applies: false` (review mode) unless the user explicitly
says to enable them right away. For a bulk change (tens/hundreds of products), first show
a before/after sample (via `query_products` on a few products) before creating the rule —
never fix blind.

## Step 4 — Actions (finding → rule mapping)

Use the dedicated `create_<type>_rule` MCP tools directly (not a generic `create_rule` and
not raw REST) — they handle the struct/array format internally. They always need
`queries: [{"id": "..."}]` (`all_products_query_id` from `list_shop_projects` for "all products").

- **Segmentation (1):** segment the target products via 2-3 `create_project_query` (e.g.
  price bands) → `create_batch_rewriting_rule` with `element_path` on `g:custom_label_0`,
  where each row (`query_id` → `value`) writes a different value for a different segment.
- **Categories (2):** `create_categories_rule`. ⚠️ It is bound to the format's category
  element (`g:google_product_category`) and **ignores a custom `element_path`** — to map
  into a different element use `create_batch_rewriting_values_rule` instead.
- **Cleanliness (3):** `create_hiding_rule` on the query from step 1. ⚠️ The server always
  forces priority to `999999` regardless of what you send — that's fine, hiding should apply last.
- **Title/description (4):** promo text in the title → `create_replacing_rule`. ⚠️
  `additional_data` (search/replace pairs) is silently dropped on POST/PATCH — the pairs
  must be added manually in the UI after creation. A short description cannot be
  auto-extended — recommendation to the user only.
- **GTIN/MPN (5):** typically a recommendation only (data must come from the source); if an
  alternative source element with the value exists, `create_rewriting_rule` with a mapping.
- **Variants (6):** if the source has the attribute elsewhere, `create_batch_copy_values_rule`
  or `create_rewriting_rule` onto `g:color`/`g:size`.
- **Images (7), Shipping (8):** recommendation to the client only — this is source data, not a rule.
- **Performance segmentation (9):** `create_data_import_rule` (CSV export from Google Ads,
  matched by `g:id`).
  1. Ask the user for a public CSV URL (published Google Sheet — `File → Share →
     Publish to web → CSV`). Base64 upload is silently dropped, do not use it.
  2. If the target elements (e.g. `Stats | clicks`, `Stats | cost`) do not exist in the
     project, **ask the user before `create_element`** — it adds new structure.
  3. ⚠️ **Known bug:** `file_matching_element_path`/`project_matching_element_path` are
     silently dropped for CSV import (returned as `null`) → the import "succeeds" but matches
     nothing. Workaround: `create_element` named exactly after the CSV matching column →
     `create_batch_copy_values_rule` (real key → that element) → `create_data_import_rule`
     with `match_by_input_values: false`.
  4. After the import, segment/hide by the result (`create_batch_rewriting_rule` into
     custom_label, or `create_hiding_rule` on the worst performers).

## General notes on writes (verified live)

- No `update_rule` — a rule must be deleted (`delete_rule`) and recreated instead of edited.
- `create_element` does not return the new element's id — call `list_project_elements` again after creating it.
- After creating a rule, verify the effect via `get_rule` and `query_products` on a sample
  after the next rebuild — never force a recalculation (`mark_*_dirty`), Mergado does it automatically.
