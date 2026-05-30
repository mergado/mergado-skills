# MCP recepty — konkrétní sled volání pro typické scénáře

Tento soubor je most mezi **uživatelovým záměrem** a **konkrétními voláními Mergado MCP toolů**. Otevři ho, když řešíš jeden ze scénářů níže — máš v jednom místě sled volání, kontroly, fallbacky a co reportovat uživateli zpátky.

> **Návod ke čtení:** Recepty jsou sekvence, ne dogma. Pokud tool selže nebo vrátí neočekávaná data, použij fallback uvedený u receptu, nebo improvizuj — ale **vždy** dodrž bezpečnostní rails ze SKILL.md (read-before-write, potvrzení před zápisem).

## Obsah
- [0. Navigation chain (povinný základ)](#navigation-chain)
- [1. Diagnostika feedu („něco se posralo")](#feed-diagnostika)
- [2. Feed se nestáhl / 0 produktů](#feed-nestaženo)
- [3. Nový výstup pro Google Shopping / Heureka / Glami](#novy-vystup)
- [4. GMC neschvaluje produkty (audit-driven)](#gmc-audit)
- [5. Doplnit chybějící hodnotu z jiného zdroje (např. barvu z TITLE)](#doplnit-hodnotu)
- [6. „Co dělá toto pravidlo?" — orientace v pravidlech](#co-dela-pravidlo)
- [7. „Stará data v Googlu / Heurece" → rebuild](#rebuild)
- [8. „Kdo to rozbil" — audit trail timeline](#audit-trail)
- [9. Pozastavit / smazat / znovuspustit projekt](#lifecycle)
- [10. Známé MCP server gaps a workaroundy](#known-issues)

---

## <a name="navigation-chain"></a>0. Navigation chain (povinný základ)

**Toto je výchozí trasa, kterou musíš dodržet u všech scénářů.** Globální seznamy (`list_shops`, `list_projects` na úrovni celého API) nepoužívej. Proto se k cíli **vždy** propracováváš přes:

```
[uživatel] → list_user_eshops(user_id) 
          → list_shop_projects(shop_id) 
          → list_project_apps / list_project_rules / list_project_elements / list_project_products
          → get_rule / get_element / ...
```

### Identifikace uživatele

`get_current_user` má **schema mismatch** — typicky vrátí chybu. Workaroundy v pořadí preference:

1. Pokud znáš user_id z předchozí konverzace nebo z `list_users` → použij ho rovnou.
2. Zeptej se uživatele na e-mail nebo user_id (typicky to ví — vidí ho v Mergado UI).
3. Jako poslední možnost zavolej `list_users` (na test účtech vrátí jediného usera; v produkci větší).

**Nikdy** nepřesune skill bez znalosti user_id — bez něj nemůžeš zjistit, k jakým e-shopům uživatel patří.

### Když uživatel má víc e-shopů / projektů

1. Po `list_user_eshops` ukaž seznam e-shopů srozumitelně (`První eshop (ID 55465) — Shoptet CZ`).
2. Zeptej se, kterého se to týká.
3. Po `list_shop_projects` zase ukaž projekty s typem (`Google Nákupy [CZ] — výstup pro Google Shopping`).

**Antipattern:** odhad / volba prvního shopu / projektu bez potvrzení. To skoro vždy povede na špatný projekt.

---

## <a name="feed-diagnostika"></a>1. Diagnostika feedu („něco se posralo")

**Trigger fráze:** *"v projektu mi něco neklape"*, *"feed je rozbitý"*, *"furt to chybí"*.

### Sequence

```
1. Navigation chain → projekt_id
2. list_project_products(projekt_id) → count produktů (porovnej s tím, co uživatel čeká)
3. get_import_logs(projekt_id) → posledních 5–10 importů, status
4. get_export_logs(projekt_id) → posledních 5–10 exportů, status
5. get_apply_logs(projekt_id) → kdy se naposled aplikovala pravidla
6. Pokud nějaký log podezřele selhává → get_import_log(log_id) nebo get_export_log(log_id) pro detail
```

### Interpretace signálů

| Signál | Co to znamená | Akce |
|---|---|---|
| `items_processed: 0` při importu | Vstupní feed je prázdný nebo nedostupný | Zkontroluj import URL, status HTTP |
| `last_import_at` > 24 hodin | Importy se zastavily | Hledej v `get_import_log` poslední failure |
| `last_export_at` zaostává za `last_import_at` o > 1 den | Exporty se zastavily, ale imports běží | → recept #7 (rebuild) |
| `is_dirty: true` dlouho | Projekt potřebuje rebuild, ale ten se nespouští | → recept #7 |
| `is_paused: true` | Projekt je manuálně pozastavený | Zeptej se, zda úmyslně |

### Co reportovat uživateli

Konkrétní timestamp + příčina + návrh akce. Ne *"export selhal"*, ale *"Poslední úspěšný export proběhl 2026-05-13 v 9:08, pak se zastavil. Importy běží normálně. Návrh: spustím manuální rebuild — produkty se v Googlu objeví do hodiny."*

---

## <a name="feed-nestaženo"></a>2. Feed se nestáhl / 0 produktů

**Trigger fráze:** *"v projektu nejsou produkty"*, *"feed je prázdný"*, *"včera tam bylo 1200 produktů, dnes 0"*.

### Sequence

```
1. Navigation chain → projekt_id
2. list_project_products(projekt_id) → ověř, zda je opravdu 0
3. get_import_logs(projekt_id, limit=10)
4. Identifikuj poslední úspěšný + první neúspěšný log
5. get_import_log(last_failed_id) → konkrétní chyba (HTTP 404, parse error, timeout)
6. (Pokud podezření na změnu URL feedu) zjisti current input URL: navigate v project objektu
```

### Typické chyby + odpověď uživateli

| Chyba v logu | Odpověď |
|---|---|
| `HTTP 404` | "URL tvého feedu (`...`) vrací 404 od [časový stamp]. Pravděpodobně jste změnili adresu feedu v e-shopu. Můžeš mi poslat novou?" |
| `parse error` | "Feed se stáhl, ale Mergado ho neumí přečíst — XML je rozbité na řádku X. Často to vyřeší re-export z e-shopu." |
| `timeout` | "Feed se nedaří stáhnout včas — server eshopu je pomalý nebo nedostupný. Zkusíme za chvíli znovu, pokud bude problém pokračovat, podívej se na výkon e-shopu." |

### Co nedělat

- **Nedělej** žádné write akce — toto je read-only diagnostika.
- **Netvrď** *"oprav to v adminu"* bez konkretizace, kde a co.

---

## <a name="novy-vystup"></a>3. Nový výstup pro Google Shopping / Heureka / Glami

**Trigger fráze:** *"chci začít s Google Shopping"*, *"přidej mi Heureka"*, *"jak nastavit Glami"*.

### Sequence

```
1. Navigation chain → shop_id (kde má být nový výstup)
2. list_shop_projects(shop_id) → ověř, zda už výstup pro tuto platformu neexistuje
3. get_format(slug) → načti specifikaci platformy
   slugy: "google.cz", "google.sk", "heureka.cz", "heureka.sk", "zbozi.cz.1", 
          "glami.cz", "facebook.cz", "allegro.pl"
4. list_project_elements(zdrojový_projekt_id) → co máš ve vstupu
5. (Gap analysis v hlavě) → které GMC/Heureka povinnosti chybí
6. Vysvětli plán uživateli: "Vytvořím nový výstupní projekt formátu X, ten už bude napojený na tvůj vstupní feed. Chybí ti tyto povinnosti: ... — doplníme pravidly."
7. POČKEJ NA POTVRZENÍ
8. create_project (formát, shop_id, název) → output_project_id
9. Pro každou chybějící povinnost: create_rule + případně create_project_query + assign_query_to_rule
10. trigger_project_rebuild(output_project_id) → ať se hned vygeneruje výstup
11. Vrať uživateli URL výstupního feedu (najdeš ji v project objektu po vytvoření)
```

### Workaround: `list_supported_formats` selhává

Pokud `list_supported_formats` vrací schema error, **musíš znát slug** přesně. Reference seznam slugů viz výše. Nikdy nezkoušej `create_project` bez funkčního `get_format(slug)` ověření, že formát existuje — jinak vytvoříš invalid projekt.

### Tip

Začni s **jedním** výstupem (typicky Google CZ), oprav povinnosti, ukaž že funguje. Až pak nabídni další platformu. Jinak utopíš uživatele v komplexitě.

---

## <a name="gmc-audit"></a>4. GMC neschvaluje produkty (audit-driven)

**Trigger fráze:** *"Google mi disapprovuje produkty"*, *"GMC errors"*, *"feed je odmítnutý"*.

### Sequence

```
1. Navigation chain → projekt_id (Google výstup)
2. list_project_apps(projekt_id) → JE ZAPNUTÝ MERGADO AUDIT?
   ┌─ ano → 4a. použij Audit data
   └─ ne  → 4b. fallback bez Auditu
```

### 4a. Pokud je Audit zapnutý

```
3a. get_project_app(projekt_id, app="audit") → výsledky auditu
4a. Identifikuj problematické validátory (kterých produktů, kolik)
5a. search-in-knowledgebase("[konkrétní chyba GMC]") → doporučené řešení
6a. query_products(projekt_id, podmínka='element X je prázdný') → 5 ukázek
7a. Navrhni opravné pravidlo → POČKEJ NA POTVRZENÍ
8a. create_project_query, create_rule, assign_query_to_rule, update_queried_products
9a. trigger_project_rebuild → propsat změny do výstupu
10a. get_apply_log(latest) → ověř, kolik produktů bylo opraveno
```

### 4b. Pokud Audit zapnutý NENÍ (fallback)

```
3b. get_format("google.cz") → načti GMC specifikaci povinných elementů
4b. list_project_elements(projekt_id) → seznam elementů, které ve výstupu jsou
5b. (Manuální gap analysis) → identifikuj povinné, které chybí nebo můžou být prázdné
6b. query_products s podmínkou "[element] je prázdný" → kolik produktů to zasáhne
7b. Stejně jako 7a–10a výše
```

V odpovědi uživateli **upřímně** zmiň: *"Mergado Audit u tebe není zapnutý, takže pracuji s GMC specifikací přímo z knowledge base. Pokud chceš detailnější diagnostiku do budoucna, doporučím zapnout Audit (zdarma)."*

### Známá past

Element `google_product_category` musí mít **plnou cestu** (`Apparel > Shoes > Sneakers`), ne jen jedno slovo. To je častý GMC reject. Recept pro opravu v `pravidla-cookbook.md` → Kategorie.

---

## <a name="doplnit-hodnotu"></a>5. Doplnit chybějící hodnotu z jiného zdroje (např. barvu z TITLE)

**Trigger fráze:** *"800 produktů nemá barvu, ale je v názvu"*, *"doplň materiál z parametrů"*, *"chybí mi GTIN"*.

### Sequence

```
1. Navigation chain → projekt_id
2. list_project_elements(projekt_id) → existuje cílový element (např. COLOR)?
   ┌─ ano → pokračuj
   └─ ne  → create_element(projekt_id, název) (po potvrzení uživatele!)
3. query_products(projekt_id, "element je prázdný") → kolik produktů (potvrď s uživatelem počet)
4. Vymysli zdrojovou logiku:
   - Regex z TITLE: query_products vrátí ukázky → otestuj regex
   - Z jiného elementu/atributu: PARAM { @@VALUE = "Barva" } | VAL
   - Z mapy (CSV): pravidlo Import datového souboru
5. UKÁZKA PŘED APLIKACÍ: vyrenderuj 3–5 produktů s tím, co by pravidlo udělalo
6. POČKEJ NA POTVRZENÍ
7. create_variable (pokud potřeba) → např. extrakce barvy regexem
8. create_project_query → výběr produktů s podmínkou
9. create_rule (typ replacing nebo doplnit) → element ← variable nebo statická hodnota
10. assign_query_to_rule
11. update_queried_products → aplikuj na produkty
12. get_apply_log → kolik produktů reálně získalo hodnotu
13. Report uživateli: "Z 800 produktů barvu získalo 743. Zbývajícím 57 neobsahuje rozpoznatelnou barvu v názvu — můžeš mi poslat seznam barev jako CSV, nebo je necháme prázdné."
```

### Edge cases, na které upozorni proaktivně

- **Vícebarevné** (*"červená/černá"*) — pravidlo vezme první nebo všechny? Default: první, ale ptej se.
- **Zkratky** (*"červ."* místo *"červená"*) — regex je nezachytí. Doporuč uživateli rozšířit slovník.
- **Cizojazyčné** (*"red"*, *"black"*) — pokud má e-shop víc jazyků, počítej s mixem.

---

## <a name="co-dela-pravidlo"></a>6. „Co dělá toto pravidlo?" — orientace v pravidlech

**Trigger fráze:** *"co dělá pravidlo XYZ"*, *"můžu tohle pravidlo vypnout"*, *"kdo to vytvořil"*.

### Sequence

```
1. Navigation chain → projekt_id
2. list_project_rules(projekt_id) → najdi pravidlo podle názvu nebo ID
3. get_rule(rule_id) → základní info (typ, priority, state, regex flag, ...)
4. list_rule_queries(rule_id) → kterých výběrů produktů se týká
5. Pro každý query: get_query(query_id) → podmínka
6. (Optional) query_products(s tou podmínkou) → ukaž 5 reálných ukázek dotčených produktů
7. get_rule_data(rule_id) → detail (find/replace, regex, hodnota)
8. Přelož do lidské řeči:
   "Pravidlo 'Hide unavailable old' skrývá produkty s AVAILABILITY=out of stock 
    starší 30 dní. Aktivní, priorita 3. Dnes se týká 47 produktů."
9. Pokud uživatel chce vypnout:
   - Vysvětli dopad ("po vypnutí se těch 47 produktů vrátí do exportu")
   - POČKEJ NA POTVRZENÍ
   - update_rule(rule_id, state="disabled") nebo state="archived"
   - Po změně: trigger_project_rebuild ať se promítne
```

### Tip

Pravidla s prioritou `999999` jsou typicky "default app-managed" — měň je opatrně, často je řídí Mergado aplikace (Bidding Fox, Pricing Fox, FIE…).

---

## <a name="rebuild"></a>7. „Stará data v Googlu / Heurece" → rebuild

**Trigger fráze:** *"snížil jsem ceny, ale v Googlu jsou pořád staré"*, *"přepnul jsem dostupnost, Heureka to neukazuje"*, *"hni s tím"*.

### Sequence

```
1. Navigation chain → projekt_id (výstupní)
2. get_import_logs(projekt_id, limit=3) → kdy doběhl poslední import
3. get_export_logs(projekt_id, limit=3) → kdy doběhl poslední export
4. Porovnej:
   ┌─ import < uživatelova změna → "Mergado ještě nestáhl tvoje data, počkáme na další import (typicky 1–6h)"
   ├─ import OK, export starší → trigger_project_rebuild
   └─ vše čerstvé → "Mergado má aktuální data. Problém je na straně platformy — GMC stahuje feed typicky 1× za 24h."
5. Pokud rebuild: trigger_project_rebuild(projekt_id) → spustí se asynchronně
6. Po krátké chvíli get_export_logs znova → ověř, že nový export proběhl
7. Vrať uživateli URL výstupního feedu pro fetch v platformě
```

### Realistická ETA, kterou uživateli sděl

- **Mergado rebuild**: minuty.
- **Google Merchant Center fetch**: až 24 hodin (uživatel může v GMC dát "Fetch now").
- **Heureka pairing refresh**: 24–48h.
- **Meta Catalog refresh**: 60 minut typicky.

**Nikdy** neslibuj okamžitý dopad na platformě. Jen na Mergado straně.

---

## <a name="audit-trail"></a>8. „Kdo to rozbil" — audit trail timeline

**Trigger fráze:** *"včera mi to fungovalo, dnes je chaos"*, *"kdo upravoval pravidla"*, *"co se stalo za posledních 48h"*.

### Sequence

```
1. Navigation chain → projekt_id
2. get_apply_logs(projekt_id) → kdy se aplikovala pravidla (rules_changed_at)
3. get_import_logs(projekt_id) → operace s feedem
4. get_export_logs(projekt_id) → operace s výstupem
5. get_access_logs(user/shop) → kdo se přihlásil (může vyžadovat shop_id)
6. get_shop_event_logs(shop_id) → změny na shop úrovni
7. Sestav TIMELINE chronologicky → seřaď podle timestampu
8. Vyzdvihni POTENCIÁLNÍ KORELACI s problémem:
   - "17.5. 14:23 — jan@firma.cz upravil pravidlo 'Price boost'"
   - "17.5. 18:00 — import OK"
   - "18.5. 02:14 — automatický rebuild po změně pravidla"
   - → "Začni s pravidlem 'Price boost' — bylo upravené těsně před problémem."
```

### Co dělat / nedělat

- **Reportuj fakta, nesoudbě.** Místo *"kolega Honza to rozbil"* řekni *"poslední úpravy v okolí problému provedl honza@..., konkrétně pravidlo X. Není to obvinění — možná tu úpravu bylo třeba; jen je to startovní bod, kde hledat."*
- Pokud `user_id: null` u logu — to je **automatika**, ne uživatel. Většinou planovaný rebuild nebo periodický import.
- Pokud `get_access_logs` selhává nebo je prázdný — řekni to upřímně a sestav timeline jen z toho, co máš.

---

## <a name="lifecycle"></a>9. Pozastavit / smazat / znovuspustit projekt

**Trigger fráze:** *"sezona skončila, pozastav projekt"*, *"smaž mi Heureku"*, *"znovuspusti Glami"*.

### Sequence

```
1. Navigation chain → najdi konkrétní projekt
2. Ověř aktuální stav v list_shop_projects: is_paused, deleted_at
3. ROZLIŠ A POTVRĎ S UŽIVATELEM:
   - Pozastavit (is_paused=true) — export se zastaví, fakturace pokračuje, lze kdykoli znovu zapnout
   - Smazat (delete_project) — NEVRATNÉ, fakturace končí, projekt zmizí
   - Snížit tarif — alternativa pokud uživatel chce ušetřit, ne ztratit
4. Pokud get_project(id) má schema error → použij info z list_shop_projects (má vše potřebné)
5. update_project(id, is_paused=true) NEBO delete_project(id) PO POTVRZENÍ
6. Pokud pozastavujeme: upozorni na měsíční fakturaci ("Tarif jede dál — pokud chceš ušetřit, je rozdíl mezi pozastavit a smazat.")
7. Pokud znovuspouštíme: trigger_project_rebuild po unpause, ať se výstup obnoví
```

### Bezpečnostní rail

**Smazat projekt = nevratné.** Pokud uživatel řekne *"smaž to"*, **vždy** ho přibrzdi:

> *"Můžu smazat — ale chci se ujistit. Smazání je nevratné: ztratíme historii, statistiky, pravidla, URL výstupního feedu. Pokud je to jen na pár měsíců, doporučím raději pozastavit. Co preferuješ?"*

---

## <a name="known-issues"></a>10. Preferované volání a fallbacky

Některé MCP tooly mají preferovanou cestu volání. **Skill volá MCP tooly normálně podle receptů.** Pokud konkrétní volání selže, použij fallback níže, nebo řekni uživateli upřímně co se stalo a zkus alternativu (jiný MCP tool, knowledge base, případně ruční postup v UI jako poslední možnost).

### Obecný princip při selhání toolu

1. **Nelži.** Nikdy nepředstírej, že máš data, která ti tool nevrátil.
2. **Vysvětli stručně.** *"Tento konkrétní endpoint má zrovna problém — zkusím to obejít přes [alternativní cestu]."*
3. **Nabídni alternativu** — jiný MCP tool, knowledge base, případně ruční postup v UI jako poslední možnost.
4. **Pokračuj v práci.** Pokud žádný fallback nezabere, navrhni uživateli ruční postup v Mergado UI.

### Fallbacky pro konkrétní tooly

**U těchto toolů použij list endpointy:**

| Tool | Problém | Workaround |
|---|---|---|
| `get_current_user` | Vyžaduje `user` wrapper, server vrací plochou strukturu | Zeptej se na e-mail nebo použij `list_users` |
| `get_user(id)`, `get_project(id)` | Stejný pattern | Použij `list_users`, `list_shop_projects(shop_id)` |
| `get_app_by_name(name)` | Schema vyžaduje `latest_release_date` | Použij `list_project_apps(project_id)` |
| `list_supported_formats` | Schema error | Použij `get_format(slug)` s konkrétním slugem (`google.cz`, `heureka.cz`, `zbozi.cz.1`, `glami.cz`, `facebook.cz`, `allegro.pl`) |
| `list_defined_rules` | Schema vyžaduje `total_results` | Použij hard-coded allowlist rule typů ze `slovnik-pojmu.md` |
| `element_values_post` | Schema vyžaduje neexistující `path` | Pro praktické čtení hodnot zkus `list_project_products(project_id, mql=...)` |

**U těchto operací použij přímou navigaci nebo Mergado UI:**

| Tool | Doporučená cesta |
|---|---|
| `list_shops`, `list_projects` (globální listy) | Navigation chain: `list_user_eshops(user_id)` → `list_shop_projects(shop_id)` |
| `get_shop_event_logs` | `get_access_logs(project_id)` má částečnou viditelnost |
| `create_project` | Mergado UI: eshop → Projekty → "+ Nový projekt" |
| `update_project`, `update_project(is_dirty=true)` | Mergado UI → projekt → Nastavení |
| `trigger_project_rebuild` | Mergado UI → projekt → Nastavení → Přegenerování → "Spustit export" |
| `query_products(project_id, query_id)` | Použij `list_project_products(project_id, mql=...)` s MQL filtrem |
| `list_project_products(values_to_extract=...)` | Vynech `values_to_extract`, načti hodnoty samostatně |
| `list_project_products(per_page=int)` | Vynech `per_page` |

**Billing data:**

| Tool | Doporučená cesta |
|---|---|
| `get_user_billing` | Přesměruj uživatele na `app.mergado.com/billing` |

**Pravidla s array parametry:**

| Tool | Doporučená cesta |
|---|---|
| `create_rule.queries` | Pokud volání s array selže, vytvoř pravidlo v Mergado UI |
| `create_rule.data` (array pro `batch_rewriting`) | Pro `batch_rewriting` rule použij Mergado UI |

### Tools, kde stačí ověřit výsledek po zavolání

| Tool | Použití |
|---|---|
| `create_project_query`, `delete_query` | Volej normálně a ověř výsledek přes `list_project_queries` |
| `update_variable`, `create_variable`, `delete_variable` | Po použití ověř přes `list_project_variables` |

### Allowlist user-creatable rule typů

I po opravě všech MCP bugů zůstává sémantická restrikce: některé rule typy v Mergadu vznikají automaticky systémem a uživatel by je neměl tvořit. Doporučuj pouze z této množiny:

- ✅ **User-creatable:** `rewriting` (Přepsat), `batch_rewriting`, `truncating`, `tagstripping`, `remove_diacritics`, `hiding` (Skrýt produkt), `params_remove_by_value`, `batch_set_datetime`, `batch_param`
- ❌ **System-managed (nikdy nenavrhuj):** `format_converter` (vzniká automaticky při založení projektu), `product` (vzniká automaticky když uživatel ručně upraví produkt v UI)
- ⚠️ **Format-specific:** `heurekawatchdog__pairing` — pouze projekty s output formátem Heureka

### UI vs API formát dat u pravidel

Mergado UI a API ukládají `data` u pravidel ve dvou různých strukturách (UI: `$struct/$ref/$ep`, API: `{"new_content":"..."}`). Pravidlo vytvořené přes API se zjednodušeným formátem se v UI nemusí dát otevřít (zobrazí prázdný formulář). Pokud bude chtít uživatel po vytvoření přes API ručně upravovat pravidlo v UI, doporuč mu vytvořit pravidlo rovnou v UI.

---

## Poznámka o cold-start protokolu

Pokud začínáš v **nové konverzaci** a uživatel řekne jen *"ahoj"* nebo obecný dotaz:

1. **Neskákej** rovnou na MCP volání.
2. Zeptej se: *"S čím ti můžu pomoct? Třeba opravit chyby ve feedu, přidat nový kanál (Heureka, Google), nebo se podívat, proč se ti něco neexportuje?"*
3. **Až** dostaneš konkrétní záměr, pokračuj podle příslušného receptu.

Pokud uživatel přijde s konkrétním problémem (*"Heureka mi zamítá"*), skoč rovnou do receptu — žádné zbytečné small talk.
