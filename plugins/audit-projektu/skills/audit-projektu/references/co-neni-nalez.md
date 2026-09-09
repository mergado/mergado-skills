# Co není nález

Sbírka věcí, které vypadají jako závada, ale jsou správné. **Projdi tenhle soubor před tím, než uzavřeš report**, a co odsud platí, z nálezů vyhoď. Každá položka tady je tam proto, že ji někdo v reálném auditu nahlásil omylem.

Když najdeš další takový falešný nález, dopiš ho sem se stejnou strukturou: co to vypadá, že je, jak je to ve skutečnosti, a jak to poznat.

## Mergado obecně

### `♥ALLPRODUCTS♥` není podivně pojmenovaný výběr
**Vypadá to jako:** výběr s divnými znaky v názvu, případně jako nález R16 (nekonzistentní pojmenování) nebo jako podezřelý výběr pokrývající celý feed.

**Ve skutečnosti:** je to **systémové označení pro „všechny produkty"**. Má `read_only: true` a prázdné MQL. Mergado ho v každém projektu vytváří samo, jeho ID najdeš v `get_project` v poli `all_products_query_id`.

**Jak s ním pracovat:** pravidlo, které ho má přiřazené, se prostě aplikuje na celý feed. To samo o sobě není chyba. Nálezem je to jen tehdy, když **název pravidla slibuje segment** a přitom má přiřazený tenhle výběr, což je kontrola R7. Do nálezů typu Q4 (duplicitní výběry), Q5 (osiřelý výběr) ani R16 nepatří nikdy.

### Skryté elementy `BFE_*` nejsou nedokončená práce
**Vypadá to jako:** desítky elementů, které nejdou do výstupu, tedy nález V2 (osiřelý element), R8 (pravidlo píše do elementu mimo formát) nebo „aplikace něco počítá a nikam se to nepropisuje".

**Ve skutečnosti:** elementy `BFE_*` zakládá rozšíření **Bidding Fox Elements** a `is_hidden: true` je u nich **správný a zamýšlený stav**. Jsou to výkonová data ze srovnávače (prokliky, náklady, objednávky, tržby, průměrné CPC a pozice za 1, 7 a 30 dní), určená jako vstup pro pravidla v Mergadu a pro strategie, ne jako obsah pro srovnávač. Že ve výstupním XML nejsou, je funkce, ne závada.

**Jak s nimi pracovat:** ber je jako datový zdroj pro ostatní kontroly, typicky G2b. Do nálezů typu V2, V4 ani R8 nepatří.

**Co je naopak nález:** element `BFE_*` s `is_hidden: false`. Pak do veřejného feedu odcházejí výkonová čísla eshopu a je to kontrola V5, stejná kategorie jako publikovaná nákupní cena. Druhý nález je obsahový, tedy `BFE_*` naplněné nulou u všech produktů (rozšíření běží, ale data nedostává). To ale není o skrytí.

**Nepleť si dvě rozšíření:** Bidding Fox Elements dodává elementy, Bidding Fox řídí CPC. Jsou to samostatné instalace a jen druhé z nich má MCP server. Rozlišovací tabulka je v `detekce-rozsireni.md`, sekce 1.

## Zboží.cz a Sklik

### Makra `{network}`, `{bidtype}`, `{adtitle}` v URL jsou v pořádku
**Vypadá to jako:** nenahrazená makra ve výstupu, tedy rozbité adresy u celého feedu. Svádí to k nálezu nejvyšší závažnosti, protože zasahuje 100 % produktů.

**Ve skutečnosti:** u projektů pro Zboží.cz a Sklik **makra ve feedu zůstat mají**. Nahrazuje je až reklamní systém při odkliku, takže ve výstupním XML jsou správně nerozvinutá. Patří sem `{network}`, `{bidtype}`, `{adtitle}` a další zástupné symboly téhož druhu.

**Jak to poznat:** rozhoduje cílový formát projektu (`output_format` z `get_project`). U `zbozi.cz*` a u feedů pro Sklik to nález není. U feedu pro Google nebo Heureku by nerozvinuté makro nález byl, protože tam ho nikdo neinterpretuje.

**Důsledek pro kontrolu F3:** nehlas nerozvinutá makra jako chybu, dokud neověříš, že cílový kanál je neumí zpracovat.

### Chybějící autorizace Zboží.cz v Keychainu není nález
**Vypadá to jako:** eshop nemá klíč pro Zboží.cz, takže feed nemá kam chodit.

**Ve skutečnosti:** **napojení na Zboží.cz přes Keychain je stará metoda a už není potřeba.** Dnes platí jen napojení na Sklik Fénix. Eshop, který má Sklik a nemá Zboží.cz, je nastavený správně.

**Co je naopak nález:** u projektu pro Zboží.cz **chybějící napojení na Sklik Fénix**. To je ta vazba, která dnes platí, a její absence znamená, že se s feedem nepracuje.

**Důsledek pro kontrolu O5b:** jako potvrzující signál hledej Sklik Fénix, ne klíč pro Zboží.cz. Když ho eshop má, nedělej z chybějícího Zboží.cz klíče závěr o nefunkčním kanálu.
