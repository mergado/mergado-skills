# Pravidla Cookbook — recepty na běžné úkoly

Recepty na typická Mergado pravidla. Každý recept obsahuje:
- **Co řeší** (lidské zadání)
- **Typ pravidla** + parametry
- **Element path** v Mergado syntaxi
- **Výběr produktů** (kdy je potřeba)
- **Tip** / co si pohlídat

> **Allowlist user-creatable rule typů:** Doporučuj k vytvoření jen tyto typy — `rewriting`, `batch_rewriting`, `truncating`, `tagstripping`, `remove_diacritics`, `hiding`, `params_remove_by_value`, `batch_set_datetime`, `batch_param`. **Nikdy nenavrhuj** `format_converter` nebo `product` (vznikají automaticky v Mergadu). `heurekawatchdog__pairing` jen pro projekty s Heureka output formátem. Detail viz `slovnik-pojmu.md`.
>
> Pokud při tvorbě pravidla narazíš na omezení MCP toolu (viz `mcp-recepty.md` sekce 10), řekni to uživateli upřímně a nabídni alternativu (typicky vytvoření pravidla v Mergado UI).

## Obsah
- [Title / titulky](#titulky)
- [Description / popisy](#popisy)
- [Kategorie](#kategorie)
- [Identifikátory (GTIN, MPN, brand)](#identifikatory)
- [Obrázky](#obrazky)
- [Cena a dostupnost](#cena-dostupnost)
- [Atributy variant (barva, velikost, gender)](#atributy)
- [Skrývání produktů](#skryvani)
- [Import dat zvenčí](#import)
- [Rebuild a synchronizace](#rebuild-sync)
- [Pokročilé](#pokrocile)

---

## <a name="titulky"></a>Title / titulky

### Recept: "Vytvoř titulky strukturovaně z brand + name + color"

```
Typ:   Přepsat
Element: g:title  (resp. TITLE pro Heureka, NAME pro Sklik)
Nová hodnota: %manufacturer% %name% %color%
Výběr:   Všechny produkty   (případně omez na konkrétní kategorie)
```

**Pohlídej:**
- Pokud nějaký z elementů (`%color%`) je často prázdný, výsledek bude mít zbytečné mezery → použij pravidlo **Najít a nahradit** s regex `\s+` → ` ` jako follow-up.
- Před aktivací ukaž 2–3 vzorky před/po.

### Recept: "Doplň 'AKCE' do titulku u zlevněných"

```
Typ:   Přepsat
Element: g:title
Nová hodnota: AKCE - %g:title%
Výběr:   produkty kde PRICE_VAT < ORIGINAL_PRICE
```

**Pozor:** Promo slova v g:title můžou způsobit GMC warning. Zvaž to dřív, než to nasadíš.

### Recept: "Odstraň marketing z titulku (Heureka)"

```
Typ:   Najít a nahradit  (s regex enabled)
Element: PRODUCTNAME
Najít:   (?i)(akce|sleva|výprodej|novinka)\s*[-!]*
Nahradit: 
```

**Tip:** Heureka párování je citlivé — `PRODUCTNAME` musí být čistý název. Marketing patří do `PRODUCT`.

---

## <a name="popisy"></a>Description / popisy

### Recept: "Sestav popis ze značky, kategorie a parametrů"

```
Typ:   Přepsat
Element: g:description
Nová hodnota: %manufacturer% %name%. Kategorie: %CATEGORYTEXT%. Materiál: %material%. Barva: %color%.
Výběr:   produkty kde g:description je prázdný
```

**Tip:** Použij pravidlo **Doplnit** místo **Přepsat**, pokud uživatel chce zachovat existující popisy a doplnit je jen tam, kde chybí.

### Recept: "Odstraň HTML z popisu"

```
Typ:   Najít a nahradit  (regex)
Element: g:description
Najít:   <[^>]+>
Nahradit: 
```

---

## <a name="kategorie"></a>Kategorie

### Recept: "Doplň google_product_category podle kategorie e-shopu"

Možnost A — pevné mapování:
```
Typ:   Přepsat
Element: g:google_product_category
Nová hodnota: Apparel & Accessories > Shoes > Athletic Shoes
Výběr:   produkty kde CATEGORYTEXT obsahuje "Boty" nebo "Tenisky"
```

Možnost B — přes vlastní mapovací CSV:
```
Typ:   Import datového souboru
Soubor: kategorie_mapa.csv  (sloupce: shop_kategorie, google_kategorie)
Klíč:    CATEGORYTEXT  →  shop_kategorie
Cíl:     g:google_product_category  ←  google_kategorie
```

**Tip:** Možnost B se hodí pro projekty s desítkami unikátních kategorií. A je rychlejší pro pár výjimek.

### Recept: "Použij Google Taxonomii ID místo plné cesty"

Google akceptuje jak ID (např. `166`), tak plnou cestu (`Apparel & Accessories > Shoes`). ID je odolnější vůči překladu — pokud uživatel řeší multi-jazyk, doporuč ID.

### Recept: "Multi-úrovňový product_type (musí mít víc než 1 hodnotu)"

```
Typ:   Přepsat
Element: g:product_type
Nová hodnota: %CATEGORYTEXT%
```

Pokud `CATEGORYTEXT` je v Mergadu uložen jako hierarchie, vyexportuje se jako `Elektronika | Mobily | Smartphone` — a to GMC pochopí jako multi-úrovňový product_type.

---

## <a name="identifikatory"></a>Identifikátory (GTIN, MPN, brand)

### Recept: "Vyčisti GTIN — odstraň mezery a pomlčky"

```
Typ:   Najít a nahradit  (regex)
Element: g:gtin
Najít:   [\s\-]
Nahradit: 
```

### Recept: "Doplň identifier_exists=no kde chybí GTIN i MPN"

```
Typ:   Doplnit  (nebo Přepsat)
Element: g:identifier_exists
Nová hodnota: no
Výběr:   produkty kde g:gtin je prázdný A g:mpn je prázdný
```

### Recept: "Doplň brand z proměnné e-shopu"

```
Typ:   Doplnit
Element: g:brand
Nová hodnota: %manufacturer%
Výběr:   produkty kde g:brand je prázdný a manufacturer není prázdný
```

---

## <a name="obrazky"></a>Obrázky

### Recept: "Escape mezer v image_link"

```
Typ:   Najít a nahradit
Element: g:image_link  (nebo IMGURL)
Najít:    
Nahradit: %20
```

### Recept: "Použij druhý obrázek jako hlavní"

```
Typ:   Přepsat
Element: g:image_link
Nová hodnota: %IMAGE@1%   (druhý obrázek v pořadí; pozice indexovaná od 0)
Výběr:   omez podle potřeby
```

### Recept: "Doplň additional_image_link ze všech IMAGE"

Toto je obvykle agregační operace — zkontroluj, jak Mergado projekt obsahuje obrázky (často `IMAGE` se opakuje). Pravidlo pak iteruje přes pozice 1..N.

---

## <a name="cena-dostupnost"></a>Cena a dostupnost

### Recept: "Sniž ceny o 10 %"

```
Typ:   Přepsat
Element: PRICE_VAT  (resp. g:price)
Nová hodnota: %PRICE_VAT% * 0.9     (Mergado podporuje matematické výrazy)
```

### Recept: "Změň formát ceny z '1290 Kč' na '1290.00 CZK'"

```
Typ:   Najít a nahradit  (regex)
Element: g:price
Najít:   (\d+)\s*Kč
Nahradit: $1.00 CZK
```

### Recept: "Nastav availability podle skladu"

Pokud má e-shop element `STOCK` nebo `STOCKS` s počtem kusů:

```
Typ:   Přepsat
Element: g:availability
Nová hodnota: in stock
Výběr:   produkty kde STOCK > 0
```

A doplňující:
```
Typ:   Přepsat
Element: g:availability
Nová hodnota: out of stock
Výběr:   produkty kde STOCK = 0 nebo STOCK je prázdný
```

---

## <a name="atributy"></a>Atributy variant (barva, velikost, gender)

### Recept: "Doplň barvu z parametru e-shopu"

E-shop často má `<PARAM><PARAM_NAME>Barva</PARAM_NAME><VAL>Černá</VAL></PARAM>`.

```
Typ:   Doplnit
Element: g:color
Nová hodnota: %PARAM { @@VALUE = "Barva" } | VAL%
Výběr:   produkty kde g:color je prázdný
```

### Recept: "Doplň gender podle kategorie"

```
Typ:   Doplnit
Element: g:gender
Nová hodnota: female
Výběr:   produkty kde CATEGORYTEXT obsahuje "Dámské"
```

(opakuj s `male` pro Pánské, `unisex` pro neutrální kategorie)

### Recept: "Pohlídej Heureka ITEMGROUP_ID pro varianty"

Heureka vyžaduje `ITEMGROUP_ID` u všech variant stejného produktu. Často je odvoditelné z `MASTER_ID` nebo z URL.

```
Typ:   Doplnit
Element: ITEMGROUP_ID
Nová hodnota: %MASTER_ID%      (nebo jiný stabilní identifikátor)
Výběr:   produkty kde ITEMGROUP_ID je prázdný a MASTER_ID není prázdný
```

**Pozor:** Hodnota max 36 znaků, jen [a-zA-Z0-9_-] (bez diakritiky, bez mezer).

---

## <a name="skryvani"></a>Skrývání produktů

### Recept: "Skryj vyprodané produkty"

```
Typ:   Skrýt produkt
Výběr:   produkty kde g:availability = "out of stock"
        nebo STOCK = 0
        nebo DELIVERY_DATE > 14 (čekání > 14 dní)
```

### Recept: "Skryj produkty bez obrázku"

```
Typ:   Skrýt produkt
Výběr:   produkty kde IMGURL je prázdný
```

### Recept: "Skryj produkty pod cenou X"

Účelnost: levné produkty často mají špatnou rentabilitu reklamy.

```
Typ:   Skrýt produkt
Výběr:   produkty kde PRICE_VAT < 100
```

### Recept: "Skryj produkty obsahující 'vyprodáno' v popisu"

Audit často detekuje slova jako *"vyprodáno"*, *"není skladem"* v description.

```
Typ:   Skrýt produkt
Výběr:   produkty kde DESCRIPTION obsahuje (regex) "(vyprodáno|není skladem|sold out|nedostupn)"
```

---

## <a name="import"></a>Import dat zvenčí

### Recept: "Doplň marže z Excel tabulky"

Uživatel má xlsx s `produkt_id, marže_proc`. Export jako CSV → upload nebo URL.

```
Typ:   Import datového souboru
Soubor: marze.csv (URL nebo upload)
Klíč:    g:id  ↔  produkt_id
Cíl:     g:custom_label_3  ←  marže_proc
```

**Tip:** Custom labely jsou ideální nosič dat pro segmentaci v Google Ads / Meta — používej je pro marže, sezóny, výkon, prioritu.

### Recept: "Synchronizuj sklady ze samostatného feedu"

```
Typ:   Import datového souboru
Soubor: sklady.xml  (URL — pravidelně načítaná)
Klíč:    g:id  ↔  product_id
Cíl:     STOCK  ←  qty_available
```

---

## <a name="rebuild-sync"></a>Rebuild a synchronizace

Pravidla nejsou jediná write akce, kterou v Mergadu provádíš. Druhá klíčová operace je **rebuild projektu** — donucení Mergada, aby teď ihned vygenerovalo nový výstupní feed s aktuálními pravidly a aktuálními daty.

### Recept: "Spustit manuální rebuild projektu"

```
Tool:       trigger_project_rebuild(projekt_id)
Trigger:    "snížil jsem ceny, ale v Googlu jsou pořád staré"
            "změnil jsem pravidlo, chci ho hned vidět ve feedu"
            "exporty se zastavily, hni s tím"
```

**Před spuštěním ověř:**

1. **Stav importu** — `get_import_logs(projekt_id, limit=3)` — proběhl import s aktuálními daty? Pokud ne, rebuild nepomůže (vygeneruje výstup ze starých vstupních dat).
2. **Stav exportu** — `get_export_logs(projekt_id, limit=3)` — exporty fungují? Pokud poslední export byl před chvílí a uživatel chce hned další, je to validní use case. Pokud exporty selhávají, rebuild je trefí stejnou chybou.
3. **`is_dirty: true`** — pokud ano, rebuild je opodstatněný.

**Po spuštění:**

1. Rebuild běží asynchronně. Po ~30s zavolej `get_export_logs` znova, zda začal nový log.
2. Vrať uživateli **URL výstupního feedu** (z project objektu) — odkud si ho platforma stáhne.
3. **Realistická ETA na propagaci do platformy** (zmínit explicitně!):
   - Mergado rebuild: minuty
   - Google Merchant Center fetch: až 24 hodin (uživatel může v GMC dát "Fetch now")
   - Heureka: 24–48 hodin
   - Meta Catalog: typicky 60 minut
   
   **Nikdy** neslibuj okamžitý dopad v platformě — jen v Mergadu.

### Recept: "Kdy NEspustit rebuild"

- **Import neproběhl s aktuálními daty.** Rebuild vyrobí stejný výstup, jen znovu — žádný benefit.
- **Pravidla selhávají při aplikaci** (`get_apply_logs` ukazuje errors). Rebuild je trefí stejnou chybou. Nejdřív oprav pravidla.
- **Projekt je v `is_paused: true`**. Před rebuildem buď unpause.

### Recept: "Po každé write akci do projektu zvaž rebuild"

Když vytvoříš/upravíš/smažeš pravidlo, vytvoříš element, importuješ data — změna se projeví v exportu **až při dalším naplánovaném exportu** (typicky každých 4–6 hodin). Pokud uživatel chce vidět výsledek hned, **navrhni rebuild**:

> *"Pravidlo aktivováno. Mergado teď automaticky přegeneruje výstupní feed při dalším naplánovaném exportu (cca v 18:00). Pokud chceš změnu vidět v Googlu hned, spustím manuální rebuild — výstupní feed bude aktuální do 1–2 minut, pak ještě GMC potřebuje až 24h na fetch. Spustit rebuild?"*

---

## <a name="pokrocile"></a>Pokročilé

### Recept: "Přidej AI-doplněnou kategorii s vyšší confidence"

Pokud je projekt napojený na AI Enricher (MERGADO_AI elementy):

```
Typ:   Doplnit
Element: g:google_product_category
Nová hodnota: %AI_GOOGLE_CATEGORY%
Výběr:   produkty kde g:google_product_category je prázdný a AI_GOOGLE_CATEGORY confidence > 0.85
```

(Pokud Mergado neumí podmínku přes XML atribut `confidence`, zjisti to v Knowledge Base — některé verze ano, některé ne.)

### Recept: "Vlastní element pro custom_label_0 (sezóna)"

```
Typ:   Vlastní element
Element: custom_label_0
```
Pak pravidlo `Přepsat` na ten element s logikou per produkt (např. podle CATEGORYTEXT, podle ceny, podle obratu z importu).

### Recept: "Více pravidel skládat na sebe"

Když je úkol komplexní (přepiš title + odstraň marketing + odstraň double mezery), **rozděl** ho na 3 pravidla. Pořadí:
1. Přepsat (sestaví title z proměnných)
2. Najít a nahradit (odstraní marketing slova)
3. Najít a nahradit (regex `\s+` → ` `)

Tři čistá pravidla > jedno složité.

---

## Obecné principy při tvorbě pravidla

1. **Pojmenuj pravidlo větou.** `Doplnit Google kategorii pro produkty bez kategorie` > `pravidlo123`.
2. **Vždy s úzkým výběrem.** Globální pravidla bez výběru = riziko. Když je dopad globální, řekni to uživateli explicitně před aktivací.
3. **Doplnit > Přepsat**, kde to dává smysl. Doplnit nikdy neničí existující data.
4. **Náhled před aktivací.** Když pravidlo má dopad > 50 produktů, ukaž uživateli 2–3 ukázky před/po a počkej na potvrzení.
5. **Po aktivaci řekni co se stalo.** Počet zasažených produktů, jaké pravidlo, kde ho najde v UI.
