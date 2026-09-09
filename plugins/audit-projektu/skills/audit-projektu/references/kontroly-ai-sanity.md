# Volná AI pasáž

Poslední fáze auditu. Katalog kontrol umí jen to, na co někdo dopředu myslel. Tady je prostor najít zbytek. Pusť ji vždy, i u `--quick`, protože je krátká a bývá z ní nejzajímavější nález.

Pravidla zůstávají stejná: read-only, každý nález s důkazem, žádné dohady vydávané za zjištění. Nálezy z téhle fáze jdou do reportu do sekce **Další nálezy** a dostávají závažnost i kategorii stejně jako ostatní. Co nemá důkaz o dopadu, přepiš na otázku s ℹ️ do sekce Doporučené nástroje a otevřené otázky, ne na nález.

### AI1 Pohled zákazníka
Vytáhni 20 náhodných produktů z celého rozsahu feedu (ne prvních 20, různá cenová pásma a kategorie) a projdi je jako člověk, který si to chce koupit. Co by ho zmátlo, odradilo nebo naštvalo? Nekonzistentní jednotky, nepřeložený text, název, ze kterého není poznat, co se kupuje, popis o jiném produktu, cena, která nedává smysl.

### AI2 Vysvětli projekt novému kolegovi
Popiš vlastními slovy, co projekt dělá: co přichází na vstupu, co s tím pravidla postupně dělají a co vypadává na výstupu. Nelogičnosti vylezou samy ve chvíli, kdy to má dávat smysl jako vyprávění. Místa, kde nedokážeš vysvětlit, proč tam něco je, jsou nález nebo aspoň otázka do reportu.

### AI3 Reverse engineering záměru
Z názvů pravidel a výběrů odhadni, jakou strategii chtěl autor postavit. Pak najdi místa, kde implementace tu strategii nedodržuje. Formuluj jako "podle názvů to vypadá, že cílem bylo X, ale Y to porušuje".

### AI4 Co v projektu nemá být
Hledej stopy nedokončené nebo zapomenuté práce: testovací pravidla, poloviční migrace (nový element existuje vedle starého a oba se plní), dvě různá řešení stejného problému, pravidla s poznámkou pro člověka v názvu, konfigurace zjevně zkopírovaná z jiného eshopu (v hodnotách je cizí značka nebo cizí domény).

### AI5 Co chybí
Otoč perspektivu: co by v projektu tohohle typu být mělo a není? Podle cílové platformy a sortimentu. Chybějící čištění názvů, chybějící skrývání nedostupných produktů, chybějící doplnění značky, žádná kontrola nad cenou, chybějící UTM. Absence není vždy chyba, ale patří do reportu jako otázka.

### AI6 Sebekontrola auditu
Než uzavřeš report, projdi si ho a odpověz sám sobě:
- Je u každého nálezu důkaz, který si čtenář může sám ověřit?
- Má každý nález kategorii, tedy [DATA FEEDU], [NASTAVENÍ MERGADA], [ROZŠÍŘENÍ], [OMEZENÍ PLATFORMY] nebo [MIMO FEED]? A sedí? Nález, do jehož elementu zapisuje pravidlo, není [DATA FEEDU].
- Je nález se šesti a více zasaženými objekty popsaný jako vzorec, tedy dotčený výběr nebo MQL podmínka, ne jako výčet produktů?
- Je verdikt v předepsaném tvaru, včetně jmenovatele s počtem relevantních kontrol?
- Má tabulka pokrytí všech osm řádků, i ty, které se projektu netýkají?
- Je podpis skillu v běhu právě dvakrát, tedy v ohlášení a na konci reportu, a nikde jinde?
- Vytáhl jsem si ve fázi 0 `get_format_specification`, a zkontroloval jsem duplicity u **všech** elementů s `is_unique: true`, ne jen u `ITEM_ID` a `EAN`?
- U kontrol ze seznamu „strana hodnoty je určená" (F1, B6, B2, B3, V4, V5) jsem měřil na předepsané straně, a u elementů s origin `from_rule` na obou?
- U značky, kategorie a názvu parametru jsem prošel všechny hodnoty, nebo jen první stránku? Tvrzení „žádná zástupná značka" po jedné stránce neplatí.
- Netvrdím u konkurujících pravidel a překrývajících se šablon, které vyhraje, aniž bych to ověřil?
- Neuvedl jsem počet z celého feedu tam, kde jsem měřil na vzorku?
- Je v reportu poctivě uvedené vše, co se nezkontrolovalo, a proč?
- Nemám nález, který je ve skutečnosti legitimní vlastnost eshopu (dárkové poukazy, unisex sortiment, celoroční sezónní zboží)?

Co v téhle kontrole neprojde, z reportu vyhoď nebo přepiš na otázku.
