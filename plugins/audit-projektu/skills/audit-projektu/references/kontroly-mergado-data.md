# Kontroly dat feedu (Mergado)

Před každou kontrolou ověř, že potřebný element v projektu existuje (`list_project_elements`). Chybí-li, kontrola se přeskočí, pokud u ní není napsáno jinak.

Element paths se liší podle formátu. Níže jsou uvedené typické názvy pro Heureka XML a Google. **Vždy použij skutečný path z projektu**, ne ten z téhle tabulky.

**Nejdřív si projdi fázi 1a (levný sběr) ze SKILL.md.** Kontroly D1, D2, B1, B2, B3, A4, C2b, C4, O10 a G2b se dají zodpovědět z `list_unique_element_values`, tedy za zlomek ceny. Do MQL jdi až pro to, co z rozdělení hodnot vyčíst nelze.

Když už MQL potřebuješ, počítej z `total_results` (`list_project_products` s `mql` a `limit: 1`) a **vrácenou kartu produktu vytěž na všechny kontroly, na které v ní najdeš důkaz**, ne jen na tu, kterou jsi zadal. Ukázky max 5 produktů na nález.

## A. Cenová logika

### A1 Nákupní cena vyšší nebo rovná prodejní
**Z1.** Podmínka: existuje element s nákupní cenou (často z data importu, typicky `PURCHASE_PRICE`, `NAKUPNI_CENA`, vlastní element).
Detekce: MQL neumí spolehlivě porovnat dva elementy. Zúž výběr na produkty, které nákupní cenu mají (`PURCHASE_PRICE > 0`), stáhni po dávkách a porovnej lokálně s prodejní cenou. Spočítej i marži v procentech.
Pozor: nákupní cena bývá bez DPH, prodejní s DPH. Zkontroluj, ve které daňové bázi jsou oba elementy, jinak nahlásíš falešně celý feed. Když si bází nejsi jistý, napiš to do nálezu jako předpoklad.

### A2 Marže mimo rozumné rozmezí
**Z1 pro zápornou, Z2 pro absurdně vysokou.** Podmínka jako A1.
Detekce: marže < 0 %, nebo marže > 90 % (u běžného retailu indikuje chybu v datech, ne skutečný zisk). Seskup po kategoriích, ať je vidět, jestli je to systémové.

### A3 Cena bez DPH vyšší než cena s DPH
**Z1.** Podmínka: projekt má oba elementy (`PRICE` a `PRICE_VAT`).
Detekce: porovnání po dávkách. Typicky jde o prohozené elementy v mapování nebo v pravidle.

### A4 Sazba DPH neodpovídá typu produktu
**Z2.** Podmínka: existuje element s DPH.
Detekce: pro každou hodnotu DPH z `list_unique_element_values` vytáhni vzorek produktů a nech AI posoudit, jestli sazba odpovídá (knihy a léky nižší sazba, elektronika základní). Hlásíš jen jasné rozpory.

### A5 Falešná původní cena (Omnibus)
**Z1.** Podmínka: existuje element s původní či doporučenou cenou (`LIST_PRICE`, `PRICE_ORIGINAL`, `RRP`).
Detekce: původní cena menší nebo rovna aktuální ceně (sleva nula nebo negativní), nebo původní cena vypočtená pravidlem jako násobek aktuální ceny. Druhý případ najdeš v katalogu konfigurace (kontrola B7), tady hlásíš datový projev.
Formulace v reportu: uveď to jako právní riziko podle pravidel o oznamování slev, ne jen jako datovou chybu.

### A6 Nulové, jednotkové a řádově chybné ceny
**Z1.** Detekce: `PRICE_VAT <= 1`. Dál vytáhni vzorek napříč cenovými pásmy a nech AI posoudit, jestli cena odpovídá produktu podle názvu a kategorie (chybějící nebo přebývající nula). Porovnej cenu produktu s mediánem ceny v jeho kategorii, odlehlé hodnoty o dva řády jsou kandidáti.
Pozor: dárkové poukazy, vzorky, montáž a doplňkové služby mají legitimně nízkou cenu. Před nahlášením se podívej na název.

### A7 Cena za kus versus cena za balení
**Z2.** Detekce: v názvu nebo parametru je počet kusů (`100 ks`, `balení 24`), a cena odpovídá jednotce. Zúž MQL na názvy obsahující "ks", "balení", "pack", pak posuď vzorek AI proti ceně srovnatelných produktů.

### A8 Měna nebo cenová hladina neodpovídá cílové platformě
**Z1.** Detekce: `get_project` (výstupní formát a cílová země) proti elementu s měnou a proti absolutní úrovni cen. CZK ceny ve feedu pro SK kanál poznáš i podle toho, že ceny jsou řádově 25krát vyšší, než by v EUR měly být.

## B. Dostupnost a identifikátory

### B1 Rozpor mezi elementy dostupnosti
**Z2.** Detekce: kombinace, které si odporují - text "skladem" a zároveň `STOCK = 0`, nebo `DELIVERY_DATE > 0` u produktu označeného jako okamžitě dostupný. Vyjmenuj konkrétní kombinace hodnot a jejich počty.

### B2 Duplicitní ITEM_ID
**Z1.** Detekce: `list_unique_element_values` na `ITEM_ID` a porovnání počtu unikátních hodnot s celkovým počtem produktů. Rozdíl znamená duplicity. Platformy duplicitní ID odmítají nebo přepisují.

### B3 Duplicitní nebo neplatné GTIN a EAN
**Z2.** Detekce: stejný EAN u produktů s různým názvem (typicky varianty, které dostaly EAN rodiče). Ověř kontrolní součet EAN-13 lokálně. Zvlášť hlídej EAN identický s `ITEM_ID`, to je znak chybného mapování.

### B4 Chybějící GTIN u brandovaných produktů
**Z2. Absence je nález.** Podmínka: cílová platforma je Google Shopping nebo obdobná.
Detekce: produkty, kde je značka vyplněná a EAN prázdný. Google to trestá omezením zobrazení.

### B5 Vadné skupiny variant
**Z2.** Podmínka: existuje `ITEMGROUP_ID`.
Detekce: skupiny s jediným členem (varianta bez varianty, zbytečně tříští data) a naopak skupiny, kde jsou slepené různé produkty. Druhý případ: vytáhni vzorek skupin, dej AI názvy členů a nech ji posoudit, jestli jde o varianty jednoho produktu.

### B6 Porušená unikátnost elementu vynucená formátem
**Z2, u párovacích elementů Z1.** Podmínka: `get_format_specification` na výstupní formát z fáze 0.
Detekce: vyber z `item_schema` **všechny** elementy s `is_unique: true` a u každého porovnej počet unikátních hodnot s počtem produktů, které hodnotu mají.
**Nepočítej proti celkovému počtu produktů.** `list_unique_element_values` prázdné hodnoty nevrací, takže element, který část produktů nemá, vypadá konzistentněji, než je. Ověřený případ: `EAN` mělo 9 042 unikátních hodnot při 9 114 produktech, což vypadá téměř bez duplicit, ale 44 produktů EAN nemělo, takže duplicit bylo 54, ne 72.
Závažnost odstupňuj podle `pairing_elements` z `get_project`. Duplicita v párovacím elementu láme identitu produktu mezi importy, tedy Z1. Duplicita v ostatních unikátních elementech je Z2.
**Kontroluj vstupní i výstupní stranu.** Element přepisovaný pravidlem nebo aplikací může být na výstupu unikátní jen proto, že do něj někdo vložil identifikátor produktu. Ověřený případ: `IMGURL` přepsaný Feed Image Editorem měl na výstupu 9 114 unikátních hodnot z 9 114 produktů, ale na vstupu 9 101 a jedna adresa byla u 14 produktů. Kontrola provedená jen na výstupu vrací nulu vždycky.
Proč to vadí: platforma podle unikátních elementů páruje nabídky do karet produktů. Dvě nabídky se stejným názvem nebo stejným obrázkem se slepí do jedné, nebo se navzájem přebijí, takže část sortimentu z katalogu zmizí.
Souvisí: B2 (`ITEM_ID`) a B3 (`EAN`) jsou zvláštní případy téhle kontroly. Když ji provedeš, uveď u nich, že jsou pokryté, ať se nepočítají dvakrát.

## C. Rozpory mezi názvem, parametry, kategorií a popisem

Tahle sekce je jádro logického auditu a bez AI ji nejde udělat. Postup je vždy stejný: zúžit MQL, posoudit vzorek, hlásit s ukázkami.

### C1 Gender v názvu versus kategorie
**Z2.** Detekce: MQL na názvy obsahující "pánsk", "dámsk", "chlapeck", "dívč", "men", "women", pak porovnání s `CATEGORYTEXT` daného produktu. Hlásíš produkty, kde název tvrdí jedno a kategorie druhé.
Pozor: unisex produkty a produkty typu "dárek pro muže" v neutrální kategorii nejsou nález.

### C2 Barva, velikost, kapacita a materiál v názvu versus parametr
**Z2.** Podmínka: existují parametry.
Detekce: vytáhni vzorek produktů, které mají v názvu hodnotu odpovídající parametru (barva, kapacita v GB, velikost, materiál), a porovnej. Hlásíš rozpory typu "černý" v názvu a parametr Barva = bílá, nebo "256GB" v názvu a parametr 128 GB.
Syntaxe: konkrétní parametr se adresuje podmínkou, `PARAM { PARAM_NAME = "Barva" } | VAL`. Zápis `[PARAM | PARAM_NAME]` vrací tiše 0.

### C2b Více názvů parametru pro tutéž vlastnost
**Z2.** Detekce: `list_unique_element_values` na `PARAM | PARAM_NAME` s `is_output: true`. Hledej názvy, které znamenají totéž (Objem a Objem_ml, Datum exspirace a Datum minimální spotřeby a Datum minimální trvanlivosti, Hmotnost a Váha).
Proč to vadí: platforma filtruje podle názvu parametru, takže tři varianty znamenají tři nesloučitelné filtry a žádný z nich nemá plný počet produktů.
Souvisí s tím kontrola R2 v katalogu konfigurace: dvě pravidla plnící stejný název parametru různými proměnnými.

### C2c Datum v parametru je v minulosti
**Z1 u potravin a spotřebního materiálu, jinak Z2.** Podmínka: existuje parametr s datem exspirace, trvanlivosti nebo záruky.
Detekce: `PARAM { PARAM_NAME = "Datum exspirace" } | VAL ~ "\d\d\.0[1-7]\.2026"` a obdobně pro starší roky a pro dny aktuálního měsíce, které už minuly. Datum ber ze systémového kontextu a **pokrytí měsíců si ohlídej**, jinak nahlásíš méně případů, než jich je.
Proč to vadí: inzerce potraviny po datu exspirace je zaplacený proklik na zboží, které nelze odeslat, a reklamace, pokud odejde.

### C3 Velikostní nebo věková kategorie neodpovídá produktu
**Z2.** Detekce: dětské velikosti nebo věkové údaje v názvu u produktů v kategorii pro dospělé, produkty pro jeden druh zvířete v kategorii pro jiný. Zúž na kategorie, kde to má smysl, a posuď vzorek.

### C4 Kategorie nesouvisí s produktem
**Z2.** Detekce: dej AI vzorek (název, případně popis) bez kategorie, nech ji navrhnout kategorii, a porovnej s `CATEGORYTEXT`. Hlásíš jen výrazné rozpory, ne jemné odchylky ve větvení.
Doplňkové kontroly na stejném datovém základě: podíl produktů v kategorii typu "Ostatní" nebo "Nezařazeno", a podíl produktů s hloubkou kategorie 1 (jednoúrovňová kategorizace u velkého feedu je Z2 nález sama pro sebe).

### C4d Feed míchá víc kategorických taxonomií
**Z2.** Detekce: `list_unique_element_values` na element kategorie, z každé hodnoty vezmi **první uzel cesty** (text před prvním oddělovačem) a spočítej, kolik různých korunových uzlů feed má. U jednoho eshopu jich bývá jednotky. Desítky znamenají, že se v jednom elementu potkalo víc stromů, například `Počítače | …` vedle `Elektronika | Počítače a notebooky | …` vedle `IT | …`.
Hlídej i **dvě znění téhož uzlu** (`TV a audio-video` proti `TV, audio, video`) a nejednotný oddělovač (`|` proti `>`).
Proč to vadí: každý výběr postavený na kategorii pokrývá jen jeden ze stromů a zbytek tiše míjí. Je to nejčastější příčina toho, že pravidlo „funguje", ale na polovinu sortimentu nedosáhne. Souvisí s Q7 a Q8.
Pozor: prefix názvu srovnávače (`Heureka.cz | …`) u části produktů a ne u zbytku je stejný nález, i když strom pod ním je jinak shodný.

### C5 Popis v rozporu s názvem nebo parametry
**Z2.** Detekce: vzorek, ve kterém AI hledá rozpor mezi popisem a názvem, nebo zmínku jiného produktu v popisu (typicky po nedokončeném copy paste).

### C6 Duplicitní popisy
**Z3.** Detekce: hash nebo prvních 200 znaků popisu přes vzorek, spočítej nejčastější varianty. Stejný popis u stovek produktů je slabý content i pro vyhledávače.

### C7 Zakázaný obsah v popisu a názvu
**Z2.** Detekce MQL na popis a název: zmínky ceny ("Kč", "cena", "sleva %"), dopravy ("doprava zdarma", "poštovné"), kontaktů ("@", "tel", "www", "http"), HTML entity ("&nbsp;", "&amp;", "<br"), stav "vyprodáno" v textu. Heureka i Google to zakazují nebo penalizují.

### C8 Cizí jazyk ve feedu
**Z2.** Detekce: vzorek popisů a názvů, AI určí jazyk a porovná s cílovou zemí projektu. Anglický nebo slovenský popis v CZ feedu je nález, u jednotlivých produktů typicky nepřeložený import od dodavatele.

## D. Značka

### D1 Prázdná nebo zástupná značka
**Z2.** Detekce: `list_unique_element_values` na element značky, plus MQL `= ""` na prázdné hodnoty (unikátní hodnoty prázdné nevracejí).
**Projdi všechny hodnoty, ne první stránku.** Značek bývá pár stovek, tedy tři až pět stránek po 60, a je to nejlevnější typ dotazu, jaký existuje. Kontrola provedená na patnácti nejčastějších hodnotách nic nedokazuje, protože zástupná značka je typicky ve středu rozdělení.
**Hledej vzor, ne seznam: hodnotu, která není jméno výrobce.** Hodnoty "Ostatní", "Bez značky", "N/A", "-", "unknown" jsou příklady, ne filtr. Ověřený případ, na kterém pevný výčet selhal: značka `NoName` u 127 produktů a `OSTATNÍ - VÝPRODEJ` u 4 v projektu, jehož audit na základě výčtu napsal, že zástupné značky nemá ani jednu.
Zástupnou značku pozná AI z výčtu hodnot spolehlivě, když jí dáš celý seznam. Regulární výraz na to nepoužívej.

### D2 Více zápisů téže značky
**Z3.** Detekce: `list_unique_element_values` a normalizace (velká písmena, diakritika, mezery). Nike, NIKE, nike a "Nike " jsou jedna značka ve čtyřech podobách, což rozbíjí filtrování na platformě i vlastní výběry.

### D3 Značka v názvu se neshoduje se elementem značky
**Z2.** Detekce: vzorek, kde AI hledá v názvu jméno výrobce a porovná s elementem. Typicky u feedů, kde značka vznikla pravidlem z nespolehlivého zdroje.

## E. Sezónnost a čas

### E1 Sezónní nesmysl v datech
**Z2.** Detekce: MQL na názvy a popisy obsahující "zimní výprodej", "vánoční", "black friday", "valentýn", "velikonoč", "letní akce", "back to school", a porovnání s aktuálním datem ze systémového kontextu. Hlásíš, když je akce mimo své období.
Pozor: "zimní pneumatiky" nebo "vánoční ozdoby" jsou celoroční sortiment, ne akce. Rozhoduje, jestli text slibuje časově omezenou nabídku.

### E2 Zastaralý rok nebo označení novinky
**Z3.** Detekce: MQL na názvy a popisy s roky, které nejsou letošní ani loňský, a na slova "novinka", "new", "nová kolekce" u produktů, které jsou ve feedu dlouho.

### E3 Prošlá platnost akce v textu
**Z2.** Detekce: MQL na popisy obsahující "platí do", "akce do", "pouze do", extrahuj datum a porovnej s dneškem.

## F. Obrázky a URL

### F1 Chybějící, zástupné a sdílené obrázky
**Z2.** Detekce: prázdný `IMGURL`, URL obsahující "no-image", "placeholder", "default", a stejná URL obrázku u mnoha různých produktů (`list_unique_element_values` a srovnání počtů).

### F2 Nezabezpečené nebo podezřelé URL
**Z3.** Detekce: `IMGURL` nebo `URL` začínající "http://", URL na jiné domény než eshop, alternativní obrázek identický s hlavním.

### F2b Syntakticky rozbitá URL
**Z2.** Detekce: `URL ~ "\?[^?]*\?"` najde adresy s druhým otazníkem místo `&`, tedy případy, kdy se ke stávajícímu query stringu přilepily UTM parametry špatným oddělovačem. Dále `URL CONTAINS "&&"`, `URL CONTAINS "??"` a dvojité `https://` v jedné hodnotě.
Proč to vadí: parametry za druhým otazníkem se stanou součástí hodnoty předchozího parametru, takže se nezměří zdroj návštěvy a eshop může zobrazit špatnou variantu.

### F2c URL nevede na produkt v eshopu
**Z1.** Detekce: porovnej domény v `URL` s doménou eshopu. Nález: adresa vede na srovnávač (`heureka.cz`, `zbozi.cz`, `glami.cz`), na recenze, na kategorii nebo na homepage místo na detail produktu.
Nejčastější příčinu hledej v pravidlech: pravidlo, které do `URL` zapisuje hodnotu z elementu s adresou na srovnávači. V režimu `--values both` to poznáš okamžitě z rozdílu `input_value` a `value`.
Proč to vadí: platforma posílá zaplacenou návštěvnost mimo eshop, konverze se neměří a produkt nelze koupit.

### F3 UTM parametry
**Z2.** Detekce: v `URL` chybí UTM, kde je pravidlo na UTM zavedené; UTM jsou dvakrát (v URL zdroje i z pravidla); `utm_source` odkazuje na jiný kanál, než je cílová platforma projektu (například `utm_source=heureka` ve feedu pro Google). Poslední případ je častý u projektů vzniklých kopií.
**Nehlas nerozvinutá makra jako chybu**, dokud neověříš, že je cílový kanál neumí zpracovat. U projektů pro Zboží.cz a Sklik mají `{network}`, `{bidtype}`, `{adtitle}` a podobné zástupné symboly ve feedu zůstat, protože je nahrazuje až reklamní systém. Viz `co-neni-nalez.md`.

## G. Compliance cílové platformy

Nejdřív zjisti cílový formát (`get_project`, `get_format_specification`) a kontroluj jen to, co pro daný kanál platí. Neaplikuj pravidla Googlu na feed pro GLAMI.

### G1 Google Shopping
**Z2.** Promo text a superlativy v názvu ("AKCE", "SLEVA", "nejlepší"), CAPS LOCK slova, emoji, název nad 150 znaků, popis nad 5000 znaků, chybějící shipping, chybějící `condition` u bazarového sortimentu, chybějící GTIN (viz B4).

### G2 Heureka a Zboží
**Z2.** Zakázané fráze v názvu a popisu, hodnoty `EXTRA_MESSAGE` mimo povolený seznam, `DELIVERY` bloky bez dopravce nebo s nesmyslnou cenou, CPC nad limit kanálu.

### G2b CPC ve feedu pod minimem kategorie
**Z1.** Podmínka: projekt má element s CPC (`HEUREKA_CPC`) a zároveň element s minimálním CPC z dat srovnávače (`BFE_H_MIN_CPC`, dodává ho **Bidding Fox Elements**, což je jiné rozšíření než Bidding Fox, viz `detekce-rozsireni.md`).
Detekce: `list_unique_element_values` na element CPC ukáže rozdělení. Plochá jediná hodnota u celého feedu je sama podezřelá. Pak spočítej, u kolika produktů je minimální CPC vyšší než nabízené: `BFE_H_MIN_CPC > 1` (prah nahraď skutečnou hodnotou CPC).
Proč to vadí: nabídka pod minimem znamená, že produkt vůbec nesoutěží o pozice. Nevznikají náklady, ale ani obrat, a bidding nemá co řídit. Zároveň to bývá vysvětlení, proč je Bidding Fox „nastavený, ale nic nedělá".
Pozor: rozliš, kdo má CPC řídit. Pokud ho spravuje Bidding Fox, je hodnota ve vstupním feedu jen výchozí a nález formuluj jako „CPC z feedu není nikým přepisováno".

**Elementy `BFE_*` v projektu neznamenají, že CPC řídí Bidding Fox.** Dodává je Bidding Fox Elements, které samo nebiduje. Jestli CPC někdo řídí, poznáš jedině z `list_project_rules`: hledej pravidlo zapisující do elementu s CPC. Když takové není a element má `origin: input`, je nabídka CPC ta z dodavatelského feedu a neřídí ji nikdo. Typický obraz té situace: element s CPC má jen několik plochých hodnot odpovídajících minimům kategorií, a `BFE_*` s prokliky a náklady jsou nulové u všech produktů, protože kanál neinzeruje.

### G3 GLAMI
**Z2.** Chybějící nebo neznormalizovaná velikost, materiál a gender, protože na těchto atributech stojí filtrování.

### G4 Meta
**Z3.** `condition`, přepisovaná kategorie, `availability` hodnoty mimo povolený enum.
