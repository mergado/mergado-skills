# Ověřené gotchy — Mergado MCP a data

Každá položka nese datum posledního ověření naživo. Chování MCP serveru se mění — co je starší
než pár měsíců, ber jako hypotézu a před stavbou pravidla ji ověř na vzorku. Při rozporu má
přednost živý výsledek nad tímto souborem i nad popisem nástroje.

Ověřováno na produkčním Mergadu, na reálném dodavatelském feedu oblečení (17 778 variant,
výstup Shopify CSV) a na projektu s výstupem Heureka.

## Dotazy (MQL) a počty

**Elementy s `origin: from_rule` a ad-hoc MQL** — *ověřeno 14. 10. 2026*
`list_project_products` / `query_products` s ad-hoc `mql` filtrují **vstupní** hodnoty, i když
se ptáš na výstupní element. Element vytvořený pravidlem vstupní hodnotu nemá:
- `Title != ""` → 0, přitom `Title` měl na výstupu 630 různých hodnot;
- `[Materiál (…)] = ""` → 17 778, tedy „chybí všem".

**Řešení: výběr se `search_output: true`** — *ověřeno 14. 10. 2026*
Uložený výběr (`create_project_query`) se `search_output: true` se při aplikaci pravidel
vyhodnocuje **uvnitř běhu**, po pravidlech s nižší prioritou. Pravidlo cílící na „metafield
prázdný na výstupu" zasáhlo přesně 274 produktů, které převodník formátu nechal prázdné —
ostatních se nedotklo a při opakovaném běhu nepřeskakovalo.

**Počty během aplikace jsou zavádějící** — *ověřeno 14. 10. 2026*
Apply log hlásil u téhož pravidla postupně 17 678 → 14 047 → 6 725 → **274** produktů.
Průběžné číslo obsahuje i produkty, na které běh ještě nedošel. Čti až `status: success`.

**`product_count` uloženého výběru** — *ověřeno 14. 10. 2026*
- U starších výběrů seděl s živým počtem (7454 = 7454, 374 = 374).
- Čerstvě založený výběr vrací `product_count: null`.
- Výběr cílící na „chybí na výstupu" ukazoval po přepočtu **0** — výstup už byl vyplněný
  pravidlem, které na ten výběr cílí a při dalším běhu zasáhne znovu 274 produktů.
Spolehlivý počet: `list_project_products` s `mql` a `total_results`.

**Syntaxe zanořených cest** — *ověřeno 14. 10. 2026*
- `ATTRIBUTES | ATTRIBUTE { NAME = "Materiál" } | VALUE` → 10 hodnot (správně).
- `[ATTRIBUTES | ATTRIBUTE | NAME]` → tiše 0, bez chyby.
- `PARAM { PARAM_NAME = "Barva" } | VAL = ""` najde i produkty, které parametr Barva
  **vůbec nemají** (9 z 9 produktů bez jakéhokoli `PARAM`).

**Názvy elementů s mezerou** — *ověřeno 14. 10. 2026*
Musí být v hranatých závorkách: `[Farba (product.metafields.custom.farba)]`. Bez nich
`list_unique_element_values` vrátí HTTP 400 („syntax error near …") a `values_to_extract`
dokonce HTTP 500 — matoucí, vypadá to jako chyba serveru. Se závorkami vše funguje.

**`CONTAINS` ignoruje diakritiku i velikost písmen** — *ověřeno 14. 10. 2026*
„čierna", „cierna" i „CIERNA" → shodně 2161 produktů.

## Proměnné a pravidla

**Odkaz na proměnnou v pravidle: `%jméno%`** — *ověřeno 14. 10. 2026*
`%barva_z_nazvu%` → „Zelená". Zápis `{barva_z_nazvu}`, který uvádí popis nástrojů
`create_variable` a `update_variable`, se **zapíše do feedu doslova** jako text
`{barva_z_nazvu}` — pravidlo přitom proběhne „úspěšně", bez chyby.

**`update_variable` umí jen přejmenovat** — *ověřeno 14. 10. 2026 (popis nástroje)*
Regex ani cestu nezmění. Pro změnu vzoru: `delete_variable` + `create_variable` se stejným
jménem — pravidla odkazují jménem, zůstanou nedotčená.

**`update_rule` existuje a upravuje pravidlo na místě** — *ověřeno 14. 10. 2026*
Zapnutí/vypnutí (`applies`), název, poznámka i konfigurace; pozice a přiřazené výběry se
zachovají. `data` se **nahrazuje celé**, neslučuje — pošli kompletní konfiguraci.
Nezměníš jím typ pravidla, pozici (`reorder_rules`) ani výběry (`assign_query_to_rule`).

**Náhled nespouští vypnuté pravidlo** — *ověřeno 14. 10. 2026*
`apply_rules_to_traced_products` + `preview_rule_changes` proběhly jen přes pravidla s
`applies: true`; pravidlo s `applies: false` v běhu vůbec nebylo. Ukázku před/po pro vypnuté
pravidlo je proto nutné spočítat ručně, nebo pravidlo vyzkoušet zapnuté na duplikátu projektu.

**`create_batch_param_rule`** — *ověřeno 14. 10. 2026*
- S plnými cestami (`ep_param: "PARAM"`, `ep_param_name: "PARAM | PARAM_NAME"`,
  `ep_param_value: "PARAM | VAL"`) založí parametr i u produktu, který žádný `PARAM` neměl.
- Hodnota parametru může obsahovat `%proměnná%`.
- Holé názvy (`ep_param_name: "PARAM_NAME"`) backend **odmítne** — HTTP 400 „Element with
  given element_path does not exist inside the project". Nezapíše se tiše jinam.

**`create_element` nevrací id nového elementu** — *ověřeno 24. 8. 2026 (dokumentace MCP)*
Po vytvoření znovu `list_project_elements`.

**`create_rewriting_rule` na element s mezerou v názvu** — *ověřeno 14. 10. 2026*
`element_path` v `data.rows[]` v hranatých závorkách (`[Materiálové zloženie (…)]`) funguje;
stejně ho mají uložená i existující pravidla (`[Variant Price]`).

## Data

**Vícehodnotový zdroj → jednohodnotový cíl ořezává** — *ověřeno 14. 10. 2026*
Převodník formátu (dodavatelský XML → Shopify CSV) přenesl z vícehodnotového atributu
`Materiálové zloženie` („65 % bavlna" + „35 % polyester") do metafieldu jen **poslední**
hodnotu. Na výstupu: „35 % polyester" ×2457, „5 % elastan" ×897 (bavlněná trička s elastanem),
„65 % polyester" ×673 aj. — nejméně 5800 produktů; vstup 64 různých hodnot, výstup 38.
Odhalí to porovnání `list_unique_element_values` s `is_output: false` a `true`.

**`exported_items` ≠ počet viditelných produktů** — *ověřeno 14. 10. 2026*
Projekt se 17 778 viditelnými variantami hlásil `exported_items: 429` — pravidlo „Sloučení
variant" je seskupuje podle `PAIR_CODE` do produktů Shopify. Viditelnost čti z `is_hidden`.

**Staré `data_synced_at` ≠ mrtvý feed** — *ověřeno 14. 10. 2026*
Projekt s `data_synced_at` z května měl import úspěšný týž den; `items_processed: 0` znamená,
že se feed nezměnil a zpracování se přeskočilo. Rozhoduje `get_import_logs`.

**Podmíněné a vícesložkové hodnoty ve specifikaci** — *ověřeno 14. 10. 2026*
U všech 274 produktů bez složení, které ho měly ve specifikaci, obsahoval text výjimky
(„zloženie sa môže líšiť – farba 03 – …, farba 12 – …"). Naivní vzor na první „N % X" dal
na třech reprezentantech 2 špatné hodnoty ze 3; vzor na celé základní složení s vyloučením
dotčených barev 3 ze 3 správně (252 doplněno, 22 ponecháno prázdných).
