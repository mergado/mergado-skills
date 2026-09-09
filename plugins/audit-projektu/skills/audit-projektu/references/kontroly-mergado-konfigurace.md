# Kontroly konfigurace projektu (výběry a pravidla)

Vstupní data: `list_project_queries`, `list_project_rules`, `list_rule_queries`, `list_project_elements`, `list_project_variables`, `get_rule`, `get_query`, `get_format_specification`, `get_apply_logs`.

**Než začneš tvrdit, které pravidlo vyhrává:** zjisti si, v jakém směru působí priorita v tomhle projektu (nižší číslo dřív, nebo naopak). Ověř to na dvojici pravidel, u kterých je výsledek v datech vidět. Když se to zjistit nedá, formuluj nález jako "pravidla si konkurují na stejném elementu" a **netvrď, které z nich zvítězí**. Špatně určený vítěz je horší než nález bez určení.

## Q. Výběry (queries)

**`♥ALLPRODUCTS♥` je systémové označení pro všechny produkty**, ne podivně pojmenovaný výběr. Má `read_only: true`, prázdné MQL a jeho ID je v `get_project` v poli `all_products_query_id`. Do Q4, Q5 ani R16 nikdy nepatří. Nálezem je jen tehdy, když ho má přiřazené pravidlo, jehož název slibuje segment, což je R7.

### Q1 Název výběru neodpovídá jeho MQL
**Z2.** Jádro zadání. Detekce: pro každý výběr dej AI jeho název a MQL a nech ji posoudit, jestli si odpovídají. Typické nálezy: výběr "Pánské oblečení" filtruje `CATEGORYTEXT CONTAINS "Dámské"`, výběr "Produkty nad 1000 Kč" má prahovou hodnotu 100, výběr "Bez obrázku" testuje `IMGURL != ""`.
Hlásíš s citací názvu i MQL, ať je rozpor vidět bez klikání.

### Q2 Mrtvý výběr
**Z3.** Detekce: počet produktů 0. Neber ho z `product_count`: u nově vytvořených výběrů je `null` a u starších je to **zastaralá cache**. Ověřený příklad: výběr s podmínkou `[DESCRIPTION] = ""` uvádí `product_count: 55`, přitom ve výstupu takový produkt není ani jeden, protože je mezitím opravilo pozdější pravidlo. Počet si vždy přepočítej sám a u čísla uveď, jestli je vstupní, nebo výstupní.
Když je takový výběr použitý v aktivním pravidle, zvyš na **Z2**: pravidlo nic nedělá a někdo se na něj spoléhá.

### Q3 Nechtěně široký výběr
**Z2.** Detekce: výběr obsahuje 100 % nebo skoro 100 % produktů, ale jeho název slibuje segment. Typicky po chybě v `OR` podmínce.

### Q4 Duplicitní výběry
**Z3.** Detekce: normalizuj MQL (mezery, uvozovky, pořadí podmínek) a najdi shodné. Dva stejné výběry pod různými názvy vedou k tomu, že se úpravy dělají jen v jednom.

### Q5 Osiřelý výběr
**Z3.** Detekce: výběr není použitý v žádném pravidle (`list_rule_queries` napříč pravidly) ani v žádné šabloně Feed Image Editoru (`templates_list`, pole `queries`, jen když je FIE dostupný).
Když FIE dostupný není, **nehlásíš to jako osiřelý výběr**, ale jako "nepoužitý v pravidlech, použití v rozšířeních nezkontrolováno".

### Q6 MQL odkazuje na neexistující element
**Z1.** Detekce: vytáhni z každého MQL názvy elementů a porovnej se `list_project_elements`. Nález znamená, že výběr tiše nechytá nic, typicky po překlepu nebo po změně vstupního formátu.

### Q7 MQL se opírá o hodnotu, která ve feedu už není
**Z1.** Detekce: u podmínek s konkrétní hodnotou (`= "Pánské"`, `IN [...]`, `CONTAINS "Pánsk"`) ověř přes `list_unique_element_values`, že se hodnota v elementu vyskytuje. Klasický případ: dodavatel přejmenoval "Pánské" na "Pro muže" a celá větev pravidel od té doby nic nedělá.
Tohle je nejcennější kontrola v celé sekci, protože chyba je neviditelná a nikdo o ní neví roky.

### Q8 Křehké porovnávání textu
**Z2.** Detekce: regulární výrazy používající `\b`, které je s diakritikou nespolehlivé, a regexy nebo `CONTAINS`, které chytají víc, než název naznačuje.

**MQL ignoruje diakritiku i velikost písmen**, a to jak u `CONTAINS`, tak u `~`. Výběr `PRODUCTNAME CONTAINS "pánsk"` tedy chytí i „pansk“ a výběr hledající „Kč“ chytí „produkčního“. Nález tady není citlivost na diakritiku, ale naopak podmínka napsaná v domnění, že diakritika rozlišuje. U každého takového výběru ověř vzorek skutečně vrácených produktů.

### Q9 Překrývající se výběry na stejném elementu
**Z2.** Detekce: dva výběry se nezanedbatelným průnikem (spočítej průnik složením podmínek do jednoho MQL) použité v pravidlech, která zapisují do stejného `element_path`. Výsledek pak závisí na pořadí a nikdo neví, který produkt dostane co.

## R. Pravidla

### R1 Název pravidla neodpovídá tomu, co pravidlo dělá
**Z2.** Jádro zadání. Detekce: pro každé pravidlo dej AI jeho název, typ, `element_path`, hodnoty a názvy plus MQL přiřazených výběrů. Nech ji posoudit tři věci zvlášť:
1. odpovídá název typu operace (pravidlo "Doplnit značku" ve skutečnosti maže popis),
2. odpovídá název cílovému elementu,
3. odpovídá název segmentu, na který pravidlo padá (pravidlo "Jen výprodej" má přiřazený výběr celého feedu).

### R2 Duplicitní pravidla
**Z2.** Detekce: shoda v čtveřici typ, `element_path`, přiřazené výběry, hodnoty. Pozor na dva různé zdroje duplicit: kopie projektu, a **timeout při vytváření pravidla, po kterém někdo vytvoření zopakoval** (server přitom první pravidlo uložil). Druhý případ poznáš podle velmi blízkých časů vytvoření.

### R3 Konkurující pravidla se stejnou prioritou
**Z1.** Detekce: dvě a víc aktivních pravidel se stejnou `priority` zapisujících do stejného `element_path` s průnikem výběrů. Výsledek je nedeterministický a mění se mezi přepočty, takže se chyba projevuje náhodně.

### R4 Přepsané, a tedy mrtvé pravidlo
**Z2.** Detekce: pravidlo, jehož výsledek jiné pravidlo na stejném elementu se silnější prioritou plošně přepíše. Ověř v datech: podívej se na produkty v průniku výběrů a zjisti, která hodnota v elementu skutečně je.

### R5 Pravidla, která se navzájem ruší
**Z2.** Detekce: pravidlo A přepisuje hodnotu X na Y, pravidlo B na stejném elementu Y zpět na X. Sekvence rewriting pravidel na stejném elementu si zaslouží projít celá.

### R6 Neaktivní pravidla
**Z3.** Detekce: `applies: false`. Uveď počet a jak dlouho tam leží. Doporučení formuluj jako úklid v editoru, protože pravidlo přes MCP nelze aktivovat ani upravit (`update_rule` neexistuje).

### R7 Pravidlo bez výběru
**Z2.** Detekce: aktivní pravidlo bez přiřazeného výběru, tedy padající na celý feed, jehož název přitom mluví o segmentu. Samo o sobě není chyba, chyba je rozpor s názvem a nezamýšlený plošný dopad.

### R8 Pravidlo píše do elementu, který cílový formát nepoužívá
**Z3.** Detekce: `element_path` pravidla není ve specifikaci výstupního formátu (`get_format_specification`) ani není použit jako mezikrok jiným pravidlem. Zbytečná práce při každém přepočtu.

### R9 Tichý hiding
**Z1.** Detekce: skrývací pravidla (`hiding`) a jejich souhrnný dopad. Spočítej, kolik produktů dohromady skrývají, a porovnej s počtem produktů v projektu. Nález: skrytá většina feedu, nebo skrývání, které z názvu pravidla nejde poznat.
Tohle bývá vysvětlení stížnosti "na platformě máme míň produktů, než posíláme".

### R10 Degenerované hodnoty pravidel
**Z2.** Detekce: `truncating` na 0 nebo extrémně nízký počet znaků, `rewriting` na prázdnou hodnotu, `calc` s dělením nulou nebo s nulovým koeficientem, `rounding` na řád, který cenu rozbije.

### R11 Magic numbers a zastaralé konstanty
**Z2.** Detekce: natvrdo zapsané kurzy, ceny dopravy, procenta marže a data v hodnotách pravidel. Ke každému uveď, kdy pravidlo vzniklo, a nech AI posoudit, jestli konstanta ještě může platit. Kurz z roku 2023 v cenotvorbě je Z1.

Zvláštní případ: **korekční pravidlo, které se stane škodlivým, až se zdroj opraví.** Prohození ceny a slevy u pevného seznamu ID je správné, dokud jsou ceny prohozené. Ve chvíli, kdy dodavatel feed opraví, pravidlo je prohodí zpátky a chybu způsobí samo. Poznávací znak: korekce cílí na výčet ID produktů nebo na natvrdo zapsanou hodnotu místo na podmínku, která popisuje samotnou chybu. Doporučení do reportu: přepsat na podmínku nad daty („sleva je vyšší než cena"), pravidlo se pak vypne samo.

### R12 UTM pravidla
**Z2.** Detekce: chybějící `utm_campaign`, kampaň, která zjevně skončila (obsahuje starý rok nebo název ukončené akce), `utm_source` neodpovídající cílovému kanálu projektu, a dvojité UTM (pravidlo přidává UTM do URL, které je už obsahuje, viz datová kontrola F3).

### R12b Duplicitní pravidlo, které se spustí dvakrát kvůli vyhodnocení nad vstupem
**Z1.** Detekce: dvě pravidla se stejnou operací nad stejným elementem a s podmínkou, kterou první z nich zneplatní (typicky "doplň X, pokud X v hodnotě není"). Protože výběry se vyhodnocují nad **vstupními** hodnotami, druhé pravidlo se spustí i po tom, co první svou podmínku splnil, a operace se provede dvakrát.
Ověření: vezmi produkt z průniku obou výběrů a porovnej `input_value` a `value`. Zdvojený text v hodnotě je přímý důkaz.
Příklad z praxe: dvě pravidla `PRODUCTNAME = %MANUFACTURER% %PRODUCTNAME%` s výběry `PRODUCTNAME!~MANUFACTURER` a `PRODUCTNAME NOT CONTAINS MANUFACTURER` daly na výstupu "Alfa Alfa dětské boty".
Doporučení do reportu: zrušit jedno z pravidel. Pokud má druhé zůstat jako pojistka, musí mít výběr postavený nad výstupní hodnotou (`search_output: true`), jinak se bude spouštět vždy.

### R13 Pravidlo, které reálně nic nemění
**Z2.** Detekce: `get_apply_logs` a `get_apply_log`, hledej `processed_products: 0` u aktivních pravidel. Pozor, tenhle údaj neuvádí důvod a někdy je nulový i omylem, takže nález potvrď druhou cestou: zkontroluj počet produktů v přiřazeném výběru (Q2) a existenci elementu (Q6).

### R14 Sezónní nesmysl v aktivním pravidle
**Z2.** Detekce: názvy a hodnoty pravidel obsahující sezónní a akční pojmy ("zimní výprodej", "vánoční", "black friday", "letní akce", "výprodej kolekce 2023") porovnej s aktuálním datem. Aktivní pravidlo dopisující "ZIMNÍ VÝPRODEJ" do názvů v srpnu je přesně případ ze zadání.
Rozliš pravidlo aktivní od neaktivního: neaktivní sezónní pravidlo je normální provoz (Z3 nejvýš), aktivní mimo sezónu je Z2.

### R15 Konflikt mezi aplikací a ručním pravidlem
**Z2.** Detekce: pravidlo zapisující do stejného elementu, do kterého zapisuje i nainstalovaná aplikace. Protože `list_project_apps` přes MCP nefunguje, poznáš aplikaci nepřímo podle elementů a pojmenování pravidel. Nález formuluj jako podezření k ověření v UI, ne jako potvrzený fakt.

### R16 Nekonzistentní pojmenování
**Z3.** Detekce: chybějící nebo nejednotný prefix a číslování, směs jazyků, názvy typu "nové pravidlo", "kopie", "bez názvu". Když má eshop víc projektů, porovnej konvenci mezi nimi.

### R17 Pravidlo vyrábějící falešnou původní cenu
**Z1.** Detekce: pravidlo typu `calc`, které počítá element původní ceny jako násobek aktuální ceny (například krát 1,3). Tím vzniká sleva, která nikdy neexistovala. Datový projev je v kontrole A5, tady je příčina.

### R18 Zátěž přepočtu
**Z3.** Detekce: celkový počet pravidel, počet batch pravidel s velkými mapami hodnot, a délka řetězců pravidel nad jedním elementem. Doplň časy z `get_apply_logs`. Slouží jako vstup pro performance část auditu, ne jako obvinění.

### R19 Shadow konfigurace
**Z3.** Detekce: pravidla a výběry s názvy typu "TEST", "NEMAZAT", "dočasně", "zkouška", "XXX", jméno kolegy v názvu. Uveď datum vzniku. Dočasné řešení z roku 2022 už dočasné není.

### R20 Závislost na pořadí mezi pravidly
**Z1.** Detekce: pravidlo čte nebo filtruje podle elementu, který teprve vytváří jiné pravidlo. Pokud běží dřív, pracuje s prázdnou hodnotou. Najdeš to průchodem: pro každé pravidlo zjisti, které elementy čte (výběr i zdrojová hodnota) a které zapisuje, a postav graf závislostí. Cyklus nebo obrácená hrana proti prioritě je nález.

### R21 Pravidlo odkazuje na element nebo proměnnou, která neexistuje
**Z1.** Detekce: z hodnot pravidel vytáhni všechny odkazy `%něco%` a všechny `element_path`, porovnej se `list_project_elements` a `list_project_variables`. Odkaz na neexistující element se vyhodnotí jako prázdno, takže pravidlo tiše maže hodnotu nebo vyrábí poloprázdné texty.

Pozor na falešný nález u projektů s konverzí formátu: **vstupní i výstupní název elementu existují vedle sebe.** V projektu google.cz je `description` (origin `input`) i `g:description` (origin `from_rule`), stejně `title` a `g:title`. Zápis `%description%` v pravidle tedy není překlep, ale legitimní odkaz na vstupní hodnotu. Než nahlásíš špatný path, podívej se do seznamu elementů, jestli tam opravdu není.

## V. Proměnné a elementy

### V1 Osiřelé proměnné
**Z3.** Detekce: `list_project_variables` proti výskytu v hodnotách pravidel.

### V2 Osiřelé vlastní elementy
**Z3.** Detekce: element, který nic nezapisuje ani nečte a není ve výstupním formátu.

### V3 Elementy vytvořené a nikdy nenaplněné
**Z2.** Detekce: element existuje, ale je prázdný u téměř všech produktů (`query_products` s podmínkou na prázdnou hodnotu). Typicky nedokončená úprava, na kterou se ale odkazuje výstupní mapování.

### V4 Element mimo specifikaci výstupního formátu
**Z3, ale ověř, jestli to není chtěné.** Detekce: porovnej elementy, které mají `is_hidden: false`, se `get_format_specification` výstupního formátu. Co ve specifikaci není, jde do feedu jako nestandardní element.

**Porovnávej proti `item_schema` ze specifikace, ne proti obsahu staženého feedu.** Prázdný element ve feedu chybí i tehdy, když do formátu patří, takže z feedu samotného nepoznáš rozdíl mezi „prázdný" a „mimo specifikaci", a každý z těch dvou důvodů znamená jinou opravu. Nejtypičtější případ je výstupní cenový element rozšíření (`PF_PRICE_VAT`), který bývá prázdný **a** mimo formát zároveň, viz třetí případ níže.

Rozliš tři případy, protože každý znamená něco jiného:
1. **Chtěné.** Kanál nestandardní elementy toleruje nebo je někdo cíleně používá (vlastní příznaky pro interní nástroje, elementy pro navazující zpracování). Není to nález, jen poznámka.
2. **Nedopatření.** Pomocný nebo pracovní element, který někdo zapomněl skrýt, viz V5.
3. **Výstup rozšíření, který se nikam nepropisuje.** Rozšíření spočítá hodnotu do vlastního elementu (například cenu do `PF_PRICE_VAT`), ten není ve výstupním formátu a **žádné pravidlo ho nekopíruje do skutečného cenového elementu**. Rozšíření pak pracuje naprázdno a nikdo neví proč. Tohle je Z2 a hledej to vždy, když rozšíření hlásí, že něco spočítalo, ale ve feedu se to neprojevuje.

Když se nedá rozhodnout mezi prvním a druhým případem, **napiš to do reportu jako otázku**, ne jako závadu. Ověřit to jde stažením publikovaného feedu, viz zásada 1.

### V5 Naplněný pomocný element není skrytý
**Z2.** Detekce: elementy s `origin` `manual` nebo `from_rule`, které mají `is_hidden: false`, nejsou ve výstupním formátu a **jsou naplněné daty**. Typicky se poznají podle názvu: `nakupka`, `tmp_*`, `pomocna_*`, `sleva`, `marze`, nebo podelementy AI atributů od rozšíření.
Proč to vadí: nejde jen o zvětšený feed. **Pracovní elementy často obsahují údaje, které nemají opustit eshop**, jako nákupní ceny, marže, interní příznaky nebo poznámky. Ty pak putují na srovnávač, kde je vidí konkurence. U nákupní ceny je to nejcitlivější případ, jaký v projektu najdeš.
Ověření: přítomnost elementu ve výstupu potvrď stažením publikovaného feedu podle zásady 1. Dokud to nepotvrdíš, formuluj nález podmíněně.
Doporučení: element skrýt v editoru. Správně udělaný pomocný element má `is_hidden: true`, což bývá v projektu vidět u jiných elementů, takže se dá ukázat, že autor to místy umí.
