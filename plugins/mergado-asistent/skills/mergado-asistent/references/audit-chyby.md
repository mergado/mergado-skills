# Audit chyby — mapa typických problémů a jejich oprav

Kompaktní mapa chyb, které vrací **Mergado Audit** a validátory platforem (Google Merchant Center, Heureka, Meta Catalog Manager). Pro každou skupinu chyb je popis, doporučený postup a odkaz na recept v `pravidla-cookbook.md`.

> **Když je chyba neznámá**, použij `mcp__mergado_knowledgebase__search-in-knowledgebase` — Mergado má v help.mergado.com kompletní katalog Google validátorů (`/cs/audit-produktovych-dat/google-validatory/`).

## Severity

- **ERROR** — produkt **nebude** zobrazen v reklamě. Priorita 1.
- **WARNING** — produkt může být zobrazen, ale s omezením / sníženou kvalitou. Priorita 2.
- **NOTICE** — kosmetická poznámka, neblokuje. Priorita 3.

**Vždy** opravuj ERRORs první. WARNINGs řeš v dalším kole. NOTICE nech projít, pokud uživatel o ně sám nezažádá.

---

## 1. Chybějící povinné elementy

### `Element X chybí u N produktů`
| Element | Význam | Recept |
|---|---|---|
| `g:title` chybí | Bez titulku reklama nedává smysl | Pravidlo Doplnit s `%name%` nebo `%PRODUCTNAME%` |
| `g:image_link` chybí | Bez obrázku produkt nepůjde | Pravidlo Doplnit z `%IMGURL%` nebo Skrýt produkt |
| `g:gtin` chybí | Doporučené identifikátor | Doplnit z `%EAN%` nebo `%PARAM { @@VALUE = "EAN" } | VAL%`; když není, doplnit `g:identifier_exists=no` |
| `g:brand` chybí | Povinné pro většinu kategorií | Doplnit z `%manufacturer%`; když není, podle kategorie |
| `g:google_product_category` chybí | Google taxonomie | Pravidlo Přepsat — viz pravidla-cookbook.md → Kategorie |
| `g:availability` chybí | Bez dostupnosti GMC odmítá | Doplnit `in stock` (pokud je STOCK > 0) jinak `out of stock` |
| `g:price` chybí | Cena povinná | Doplnit z `%PRICE_VAT%` (Heureka) nebo opravit zdrojový feed |
| `g:condition` chybí | Stav produktu | Default: `new` |
| `CATEGORYTEXT` chybí (Heureka) | Heureka kategorie | Mapování — viz pravidla-cookbook.md |
| `EAN` chybí (Heureka) | Identifikátor | Doplnit z PARAM nebo `%g:gtin%` |
| `ITEMGROUP_ID` chybí u variant (Heureka) | Skupina variant | Doplnit z `%MASTER_ID%` |

### Postup pro skupinu "X chybí"
1. Spusť audit, najdi konkrétní `count of affected products`.
2. Zobraz uživateli: *"U N produktů chybí [element]. Bez něj [důsledek]."*
3. Najdi nejlepší zdroj hodnoty (`%PARAM%`, `%manufacturer%`, mapa z CSV…).
4. Navrhni pravidlo **Doplnit** (ne Přepsat — Doplnit nezničí existující hodnoty).
5. Po potvrzení vytvoř, aktivuj, zopakuj audit, ověř.

---

## 2. Chybný formát hodnoty

### `Hodnota elementu X má nesprávný formát`
| Element | Typický problém | Recept |
|---|---|---|
| `g:gtin` | Mezery, pomlčky, špatný počet znaků | Najít a nahradit s regex `[\s\-]` → `` (smaže mezery a pomlčky); pak ověřit délku |
| `g:price` | Chybí měna, špatný oddělovač | Najít a nahradit — formátovací regex (viz cookbook → Cena) |
| `g:image_link` | Mezery v URL, http místo https | Najít a nahradit — escape mezer (`%20`), `http://` → `https://` |
| `g:availability` | Český text místo enum | Přepsat na `in stock` / `out of stock` podle obsahu |
| `g:condition` | Mimo enum | Přepsat na `new` |
| `g:google_product_category` | Lokalizovaný text místo Google taxonomie | Přepsat podle Google taxonomy (ID nebo official path) |
| `ITEMGROUP_ID` | Diakritika, mezery | Najít a nahradit s regex pro odstranění |

### Postup pro skupinu "Špatný formát"
1. Identifikuj přesnou chybu — co Mergado / GMC očekává vs. co reálně je.
2. Zvol pravidlo **Najít a nahradit** s regex (pokud lze opravit), nebo **Přepsat** (pokud chce hodnotu nahradit zcela).
3. **Vždy** otestuj regex na 2–3 vzorcích před aktivací — regex je easy way to break things.

---

## 3. Multi-value problémy

### `Element X obsahuje pouze jednu hodnotu`
Týká se zejména `g:product_type` a `g:google_product_category`. GMC a Google Shopping vyžadují víceúrovňové kategorie oddělené `>`.

**Oprava:**
- Pravidlo Přepsat — sestav víceúrovňovou hodnotu z Mergado interních polí (`%CATEGORYTEXT%` často obsahuje hierarchii oddělenou `|` nebo `>`).
- Pokud potřebuješ změnit oddělovač (`|` → ` > `), použij Najít a nahradit jako follow-up pravidlo.

### `Feed obsahuje víckrát element X`
Týká se elementů, které smí být ve feedu **jen jednou** (např. `fb_product_category`, `g:product_type` v Meta).

**Oprava:**
- Tohle je obvykle **chyba zdrojového feedu** (e-shop ho generuje špatně).
- Mergado pravidlem to často nepůjde opravit — jen se to musí opravit v e-shopu.
- Workaround: pokud Mergado umí "vybrat jen první výskyt", použij path `XYZ { @@POSITION = 0 }` v selektoru.

---

## 4. Obsahové chyby

### `Title je shodný s description`
Google neuznává duplicitní content — sníží relevanci nebo odmítne.

**Oprava:** Pravidlo Přepsat `g:description` na novou strukturu (např. `%manufacturer% %name%. Kategorie: %CATEGORYTEXT%. ...`). Cookbook → Description.

### `Title obsahuje promo / marketingový text` (AKCE!, SLEVA!)
GMC nemá rád "AKCE!", "SLEVA!", emoji, capitalized words.

**Oprava:**
- Pravidlo Najít a nahradit s regex `(?i)(akce|sleva|výprodej|sale|❤️|🔥)` → ``.
- Případně Přepsat title strukturovaně (`%manufacturer% %name% %color%`) — zbaví se marketingu úplně.

### `Zboží je asi vyprodáno (klíčová slova v description)`
Audit detekuje slova jako "vyprodáno", "není skladem" v `g:description`.

**Oprava:**
- Buď opravit dostupnost (pokud produkt je vyprodaný, skrýt ho).
- Nebo upravit popis pravidlem Najít a nahradit (pokud je to false positive).

### `Description je prázdný / příliš krátký`
GMC vyžaduje smysluplný popis (alespoň 10–20 znaků).

**Oprava:**
- Pravidlo Doplnit s konstrukcí (`%manufacturer% %name% — %CATEGORYTEXT%. Materiál: %material%, barva: %color%.`).
- Pokud uživatel má AI Enricher, použít `%AI_DESCRIPTION_SHORT%`.

---

## 5. Obrazové problémy

### `Image_link nedostupná / neplatná URL`
- HTTP místo HTTPS → Najít a nahradit.
- Mezery v URL → Najít a nahradit (mezera → `%20`).
- Redirect → uživatel musí opravit v e-shopu (Mergado nemůže).
- 404 → produkt je odstraněn, skrýt nebo opravit zdroj.

### `Obrázek je příliš malý` / `Obrázek nemá bílé pozadí`
**Mergado to neopraví.** Musí se vyměnit obrázek v e-shopu / DAM systému.

> Když uživatel řeší tohle, řekni upřímně: *"Obrázek samotný Mergado opravit neumí — musí se vyměnit u tebe v e-shopu. Ale můžu ti vyfiltrovat seznam produktů, kde je problém, abys věděl, co opravit."*

---

## 6. Heureka-specifické

### Produkty se nepárují na Heurece
Heureka páruje podle `PRODUCTNAME` a `EAN`. Pokud nepáruje:
1. Zkontroluj `EAN` — je vyplněný, validní?
2. Zkontroluj `PRODUCTNAME` — je čistý (bez marketingu)?
3. Zkontroluj `CATEGORYTEXT` — je správná Heureka kategorie?

**Pomocná aplikace:** Pairing Bear (placená Mergado aplikace) automatizuje párování — doporuč ji u problematických projektů.

### Chybný `ITEMGROUP_ID`
- Max 36 znaků, jen [a-zA-Z0-9_-].
- Diakritika → odstraň pravidlem (regex).
- Mezery → odstraň.
- Stejný pro všechny varianty stejného produktu.

---

## 7. Meta Catalog-specifické

### `fb_product_category vícenásobný`
Element musí být jen jednou. Pokud Mergado zdrojový feed má víc výskytů, je to chyba zdroje. Oprava: aktualizace e-shopu nebo Mergado pravidlo s `@@POSITION = 0`.

### Image rejected ("text on image" / "promotional content")
Meta měří automaticky text na obrázku. **Mergado pravidlem neopravíš.** Musí se vyměnit obrázek.

### `Out of stock products in catalog`
Meta má vlastní logiku. Ujisti se, že `g:availability` je `out of stock`, a Meta produkty automaticky ztlumí. Případně Skrýt produkt v Mergadu.

---

## 8. Když nevíš

1. Použij `mcp__mergado_knowledgebase__search-in-knowledgebase` s textem chyby.
2. Mergado Knowledge Base má katalog **Google Feed Validators 1 a 2** se všemi chybami a doporučeními.
3. Pokud nic nenajdeš, řekni uživateli upřímně: *"Tato konkrétní chyba je pro mě nová — pojď ji rozebrat krok po kroku, ať na řešení přijdeme spolu."* a začni od kontextu (který produkt, jaká hodnota elementu, co GMC říká).

---

## 9. Workflow pro hromadný "uklid feedu"

Když uživatel řekne *"udělej mi pořádek ve feedu"* nebo *"oprav všechny chyby"*:

1. **Spusť audit.** Získáš seznam všech chyb se severity a počty.
2. **Seskup chyby do logických kategorií:**
   - Chybějící identifikátory (GTIN, brand, MPN…)
   - Chybějící klasifikace (kategorie, product_type…)
   - Formátové chyby (cena, GTIN format, URL…)
   - Obsahové chyby (title, description…)
   - Dostupnost (vyprodané, out of stock…)
3. **Prioritizuj** — od ERRORů s nejvyšším počtem zasažených produktů.
4. **Postupně řeš každou skupinu:**
   - Vysvětli problém (co to je, kolik produktů zasahuje, dopad).
   - Navrhni jedno (nebo max dvě) pravidla.
   - Získej potvrzení.
   - Vytvoř, aktivuj.
5. **Po každé skupině** zopakuj audit a ukaž **rozdíl** ("Před: 47 produktů. Po: 2 produkty.").
6. **Po skončení** — souhrn co všechno jsi udělal a doporučení dalších kroků (obrázky, popisy v e-shopu, atd.).

Tohle je nejtypičtější use-case skutečného uživatele. Drž se ho.
