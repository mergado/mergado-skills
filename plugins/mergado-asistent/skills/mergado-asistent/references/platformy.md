# Reklamní platformy — povinnosti, časté chyby, triky

Tento soubor mapuje **co konkrétně každá platforma vyžaduje**, jaká jsou typická úskalí a jak v Mergadu na to.

> **Když si nejsi jistý detailem (max délka, povolené hodnoty, povinný/nepovinný),** ověř si to v Knowledge Base MCP — `help.mergado.com` má pro každý element samostatnou stránku se specifikací.

## Obsah
- [Google Shopping (Google Merchant Center)](#google-shopping)
- [Heureka.cz / Heureka.sk](#heureka)
- [Zboží.cz](#zboži)
- [Meta (Facebook + Instagram katalog)](#meta)
- [Glami](#glami)
- [Allegro](#allegro)
- [Sklik](#sklik)
- [Univerzální pravidla pro všechny platformy](#univerzalni)

---

## <a name="google-shopping"></a>Google Shopping (Google Merchant Center)

**Element prefix:** `g:` (např. `g:title`, `g:gtin`).

### Povinné elementy
- `g:id` — unikátní ID produktu (max 50 znaků, stabilní napříč exporty)
- `g:title` — název (max 150 znaků; prvních 70 zobrazí v reklamě)
- `g:description` — popis (max 5 000 znaků)
- `g:link` — URL produktu
- `g:image_link` — hlavní obrázek (1:1, alespoň 100×100, max 2000 znaků URL)
- `g:availability` — `in stock` / `out of stock` / `preorder` / `backorder`
- `g:price` — cena s DPH a měnou (např. `1290.00 CZK`)
- `g:condition` — `new` / `refurbished` / `used`
- `g:brand` — značka (povinné téměř pro všechny kategorie)
- `g:gtin` — EAN/UPC (8/12/13/14 znaků; **silně doporučené** — bez něj horší výkon)
- `g:mpn` — výrobní číslo (povinné pokud chybí GTIN)
- `g:google_product_category` — Google taxonomie (ID nebo full path)
- `g:product_type` — vlastní kategorizace (až 5 úrovní oddělených `>`); **musí mít víc než 1 hodnotu**

### Pro varianty (oblečení, obuv, atd.)
- `g:item_group_id` — skupinové ID pro všechny varianty stejného produktu
- `g:color` — barva (max 100 znaků; lze 3 barvy oddělené `/`)
- `g:size` — velikost
- `g:gender` — `male` / `female` / `unisex`
- `g:age_group` — `newborn` / `infant` / `toddler` / `kids` / `adult`
- `g:material` — materiál
- `g:pattern` — vzor

### Časté chyby a oprava

| Chyba GMC / Auditu | Co to znamená | Oprava v Mergadu |
|---|---|---|
| `Hodnota elementu gtin má nesprávný formát` | GTIN má jiný počet znaků (musí 8/12/13/14) | Pravidlo Přepsat s regex čištěním (mezery, pomlčky) nebo Doplnit z PARAM |
| `Element g:google_product_category obsahuje pouze jednu hodnotu` | GMC vyžaduje hierarchii s `>` | Pravidlo Přepsat — přidat parent kategorii |
| `Element product_type obsahuje pouze jednu hodnotu` | Stejně jako u google_product_category | Pravidlo Přepsat se zdrojem `%CATEGORYTEXT%` (Mergado má víc úrovní) |
| `Feed obsahuje víckrát element g:product_type` | Element je duplicitní | Pravidlo Skrýt nebo opravit zdroj v e-shopu |
| `Image_link obsahuje neplatnou URL` | URL nedostupná, redirect, mezery | Pravidlo Najít a nahradit — escape mezer; nebo požádat o opravu na e-shopu |
| `Title je shodný s description` | Google neuznává duplicitní content | Pravidlo Přepsat g:description s alternativní strukturou |
| `Title obsahuje promo text` | "AKCE!", "SLEVA!" v titulku — Google nemá rád | Pravidlo Najít a nahradit — odstranit promo slova |
| `Zboží je asi vyprodáno (klíčová slova v description)` | Audit detekoval slova "vyprodáno", "nedostupné" | Pravidlo Skrýt produkt s výběrem podle těch slov |

### Tipy

- **Title best practice:** `[Značka] [Název] [Klíčový atribut: barva/velikost/materiál]` — pravidlo Přepsat s `%manufacturer% %name% %color%`.
- **Vždy nastav `g:identifier_exists`** = `no` u produktů bez GTIN/MPN/brand (např. handmade) — jinak GMC chybuje.
- **GMC neuznává relativní URL** — vše musí být absolutní, https.

---

## <a name="heureka"></a>Heureka (.cz / .sk)

**Struktura:** `<SHOP>` → `<SHOPITEM>` (každá varianta jako samostatný item).

### Povinné elementy
- `ITEM_ID` — unikátní ID (max 36 znaků, jen [a-zA-Z0-9_-])
- `PRODUCTNAME` — primárně pro párování (bez "Akce", "Sleva")
- `PRODUCT` — název pro výpis (může obsahovat víc info)
- `DESCRIPTION` — popis
- `URL` — odkaz na produkt
- `IMGURL` — hlavní obrázek
- `PRICE_VAT` — cena s DPH
- `MANUFACTURER` — výrobce
- `CATEGORYTEXT` — kategorie (Heureka kategorie!) — formát `Elektronika | Mobilní telefony | Smartphone`
- `EAN` nebo `PRODUCTNO` — identifikátor
- `DELIVERY_DATE` — kdy odešleme

### Pro varianty
- `ITEMGROUP_ID` — skupinové ID variant (max 36 znaků, stejná omezení znaků jako ITEM_ID)
- `PARAM` s `<PARAM_NAME>` a `<VAL>` — variantní atributy (Barva, Velikost…)

### Časté chyby
| Problém | Oprava |
|---|---|
| Heureka kategorie nesedí | Pravidlo Přepsat CATEGORYTEXT s mapou (možno použít Pairing Bear) |
| Produkty se nepárují | Doplnit EAN, doladit PRODUCTNAME (čistý název bez marketingu) |
| Heureka označuje "vyprodáno" / "změna ceny" | Synchronizace exportu — frekvence v Mergadu, někdy přidat manual export |

### Tipy
- **PRODUCTNAME = klíč pro párování.** Drž ho konzistentní, bez „akčních“ doplňků. Marketing patří do PRODUCT.
- **Pairing Bear** (Mergado aplikace) řeší párování na Heurece automatizovaně — když má klient zoufalé párování, doporuč ji zvážit.

---

## <a name="zboží"></a>Zboží.cz

Struktura podobná Heurece, ale **vlastní formát** (jiná specifikace). Klíčové elementy: `PRODUCTNAME`, `URL`, `IMGURL`, `PRICE_VAT`, `CATEGORYTEXT` (Zboží taxonomie!), `EAN`.

### Časté problémy
- **Špatně namapované Zboží kategorie** → pravidlo Přepsat s vlastní mapou.
- **Chybí EAN** → pravidlo Doplnit z PARAM nebo z g:gtin.
- **Vyprodané produkty** → pravidlo Skrýt s výběrem podle availability.

> **Knowledge Base** má detailní specifikaci elementů Zboží.cz pod `mergado-editor/reklamni-kanaly-a-inzerce/zbozi-cz/`. V případě nejistoty si ji ověř.

---

## <a name="meta"></a>Meta (Facebook + Instagram katalog)

**Struktura:** Google-like XML s `g:` prefixem + Meta-specifické elementy.

### Klíčové elementy
- Stejné jako Google Shopping (`g:id`, `g:title`, `g:description`, `g:image_link`, `g:availability`, `g:price`, `g:link`)
- `g:condition` — `new` / `refurbished` / `used`
- `fb_product_category` — Meta vlastní taxonomie (ne Google!)
- `g:custom_label_0` až `g:custom_label_4` — pro segmentaci v Adsetech
- `g:additional_image_link` — další obrázky

### Časté chyby
| Problém | Oprava |
|---|---|
| Element `fb_product_category` se vyskytuje víckrát | Pravidlo opravit zdroj — element smí být **jen jednou** |
| Catalog Manager hlásí "neaktuální cena" | Frekvence exportu v Mergadu (Meta refresh ~1× denně) |
| Image rejected jako "promotional" | Meta nesnáší obrázky s textem/loga přes 20 % plochy. Pravidlo Mergada to neopraví — uživatel musí vyměnit obrázek v e-shopu |

### Tipy
- **Custom labels** jsou skvělý nástroj segmentace — pravidlem si je doplň podle ceny / marže / sezóny / značky.
- **Image bez textu:** Meta to měří automaticky. Když uživatel řeší rejected images, Mergado tam nepomůže — odkaž ho na úpravu obrázků.

---

## <a name="glami"></a>Glami

Specializovaný feed pro **fashion** (Glami se zaměřuje na módu a obuv).

### Klíčové elementy
- Glami má vlastní strukturu blízkou Heurece
- Povinné: identifikátor, název, brand, barva, velikost, kategorie (Glami taxonomie), URL, obrázek, cena, dostupnost, gender, věková skupina
- **Velmi přísné na fotografie** — produktové na bílém pozadí

### Časté problémy
- **Špatná Glami kategorie** → pravidlo Přepsat s mapou
- **Chybí gender / age_group** → pravidlo Doplnit (často odvoditelné z kategorie)
- **Chybí barva** → pravidlo Doplnit z PARAM nebo z popisu (regex)

---

## <a name="allegro"></a>Allegro

Polský marketplace. Mergado generuje feed s `AI_ALLEGRO_CATEGORY_ID` mapováním.

### Specifika
- Vyžaduje **detailní Allegro kategorie** (taxonomie v polštině)
- Povinné: brand, model, EAN, foto, popis polsky, parametry per kategorie
- Allegro je marketplace, ne reklama — feed se chová jiněji než Google/Heureka

### Tip
Pro Allegro silně doporuč použití Mergado Translate (aplikace) na překlad popisů do polštiny — bez toho je product listing slabý.

---

## <a name="sklik"></a>Sklik (Seznam reklama)

**Důležité:** Sklik nečte produktový feed jako Google Shopping. Sklik využívá feed pro **dynamické remarketingové kampaně** a pro **Sklik Shopping** (česká obdoba GShopping).

### Klíčové elementy
- ITEM_ID, NAME, URL, IMG, PRICE, AVAILABILITY (in stock / out of stock), CATEGORYTEXT
- Pro Sklik Shopping navíc kategorie podle Sklik taxonomie

### Tipy
- Sklik má svoji **kategorizaci** — neplet s Heureka kategoriemi.
- Sklik Shopping má méně přísnou validaci než GMC, ale kvalita titulků a obrázků pořád ovlivňuje výkon.

---

## <a name="univerzalni"></a>Univerzální pravidla pro všechny platformy

Bez ohledu na konkrétní cílovou platformu, tyto principy platí **vždy**:

### 1. Title je nejcennější políčko
Algoritmy všech platforem dělají hodně práce s titulkem — drž ho **strukturovaný, čitelný, bez marketingových výkřiků**.
- Dobrý: `Nike Air Max 90 Pánské tenisky bílé velikost 42`
- Špatný: `❤️ TOP AKCE! Boty Nike -50 % SLEVA!`

Pravidlo: `Přepsat` → `%manufacturer% %name% %color% velikost %size%` (per platforma případně lehce upraveno).

### 2. Obrázky musí být dostupné a kvalitní
- Absolutní URL, https, žádné mezery v cestě.
- Min. 100×100, ideálně 800×800+.
- Bílé/transparentní pozadí pro většinu kategorií (kromě lifestyle).

### 3. Dostupnost (availability) musí být pravdivá
- Vyprodané produkty **vždy** skrýt nebo nastavit `out of stock`.
- Pravidlo Skrýt produkt s výběrem podle availability nebo podle skladu.

### 4. Identifikátory: GTIN > MPN > brand
- GTIN (EAN/UPC) je nejvíc ceněný — kde je, doplň ho.
- Když chybí GTIN, doplň MPN a brand.
- Když nic z toho, nastav `g:identifier_exists` = `no`.

### 5. Kategorie musí být platformně-specifická
- Google: Google Product Taxonomy (ID nebo path).
- Heureka: Heureka Kategorie (jiné než Google!).
- Glami: Glami Taxonomy.
- Allegro: Allegro Kategorie (PL).

**Nepleť je.** Když uživatel říká "doplň kategorie", zjisti pro kterou platformu, a buď exaktní.

### 6. Co Mergado NEumí opravit (hard limits)

- **Kvalitu obrázků** — když je obrázek malý / špatný, pravidlo to neopraví. Musí se vyměnit v e-shopu.
- **Špatný popis v e-shopu** — pravidlo umí přeskupit a doplnit, ale špatný zdrojový popis je špatný popis.
- **Validaci platformy "promo content"** — Meta detekuje text na obrázcích, GMC zakazuje "AKCE!" v titulcích. Některé heuristiky platforem v Mergadu opravit nelze, jen je obejít vyloučením z feedu.
- **Realtime stav skladu** — feed se exportuje s frekvencí (typicky 4×/den nebo 1×/den). Mezi exportem a další synchronizací je vždy zpoždění.

Když uživatel narazí na limit Mergada, **upřímně mu to řekni** a nasměřuj na správné místo (e-shop, design tým, Mergado Aplikace, support).
