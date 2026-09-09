# Kontroly Bidding Fox

**Spouštěj jen když detekce potvrdila, že BF je dostupný a že se podařilo navázat ID projektu.** Navázání ID je tady nejslabší místo, protože `get_all_shops` a `get_all_projects` vracejí ID, na která ostatní nástroje odpovídají `Project not found`. Když ID nemáš, celou sekci přeskoč s tímto důvodem. Neauditujte místo projektu uživatele testovací fixtury.

Vstupní data: `get_project_overview`, `get_project_settings`, `get_project_settings_history`, `validate_project_settings`, `list_strategies`, `list_setting_metrics`, `get_setting_history`, `get_setting_metrics_history`, `list_products`, `get_product`, `list_product_filters`, `list_product_tags`, `list_queries`, `list_competitors`, `list_events`, `list_exports`, `get_report`.

Nikdy nevolej `manage_settings`, `manage_product_filter`, `create_product_tag`.

**Tenhle katalog je o Bidding Foxu, ne o Bidding Fox Elements.** Jsou to dvě různá rozšíření: Bidding Fox řídí CPC a má MCP server, Bidding Fox Elements jen dodává do feedu elementy `BFE_*` a MCP server nemá. Nálezy o `BFE_*` sem nepatří, řeší je katalogy dat a konfigurace (typicky G2b a V5). Rozlišovací tabulka je v `detekce-rozsireni.md`, sekce 1.

### BF0 Nainstalovaný, ale nenastavený Bidding Fox
**Z2.** Detekce: aplikační pravidlo Bidding Foxu v Mergadu je aktivní, ale `list_strategies` vrací prázdno a `get_project_overview` s `type: "diagnostics"` hlásí `products_input: 0`, `products_paired: 0`, `products_settings_ok: 0`.
Hledej pravidlo `apps.biddingfox.inputrule`, **ne** `apps.biddingfoxelements.datarule`. Druhé patří jinému rozšíření a jeho přítomnost o nastavení Bidding Foxu nevypovídá nic.
Proč to vadí: do biddingu nevstupuje ani jeden produkt, takže CPC nikdo neřídí. Spolu s kontrolou G2b (plochá hodnota CPC ve feedu pod minimem kategorie) to dává úplný obrázek: kanál je zaplacený, ale neinzeruje.
Pozor: pokud `products_not_input` vyjde větší než `products_total`, jde o vnitřní nekonzistenci diagnostiky. Uveď obě čísla a nedopočítávej z nich nic dalšího.

### BF1 Bidding na vyprodané nebo skryté produkty
**Z1.** Nejsilnější nález celé sekce a čistě cross-app: produkty s aktivním CPC, které jsou podle Mergada nedostupné nebo skryté skrývacím pravidlem, případně v exportu vůbec nejsou. Každý klik je vyhozený.
Detekce: seznam produktů s nenulovým CPC z BF, protějšek v Mergadu podle ID produktu, kontrola dostupnosti a skrytí. Uveď počet produktů a jejich denní náklad, pokud je k dispozici.
Podmínka: potřebuje dostupné Mergado i BF. Když jedno chybí, kontrola se přeskočí.

### BF2 Max CPC nesmyslné vůči ceně a marži
**Z1.** Detekce: `list_strategies` a `list_products`, porovnej maximální CPC se cenou produktu a s marží. CPC 15 Kč u produktu za 89 Kč nemá jak vydělat. Uveď nejhorší případy s poměrem CPC k ceně.

### BF3 Nesmyslně nastavené cílové PNO
**Z2.** Detekce: `get_project_settings`, `validate_project_settings`, `list_strategies`. Hodnoty typu 0,5 % (bidding se nikdy nezvedne) nebo 200 % (bidding nikdy nespadne) znamenají, že strategie nedělá to, co si autor myslí.

### BF4 Produkty bez pokrytí strategií
**Z2.** Detekce: produkty, na které nepadá žádná strategie, a jezdí tedy na výchozím CPC. Uveď kolik jich je a jaký mají podíl na nákladech.

### BF5 Překrývající se strategie a jejich pořadí
**Z2.** Detekce: strategie s průnikem podmínek, kde na výsledku záleží pořadí. Stejně jako u Mergada: pokud si nejsi jistý, jak se pořadí vyhodnocuje, nahlas konflikt a netvrď vítěze.

### BF6 Nákladové propadáky s vysokým CPC
**Z1.** Detekce: `get_report`, `list_products`, produkty s dlouhodobě nulovými konverzemi a významnými náklady, které stále běží na vysokém CPC. Uveď součet promarněných nákladů za sledované období, to je nejsrozumitelnější číslo pro klienta.

### BF7 Změna nastavení, po které se metriky zhoršily
**Z2.** Detekce: `get_setting_history` a `get_setting_metrics_history`, hledej změnu, po které následoval zlom v PNO, nákladech nebo konverzích. Uveď datum změny, co se změnilo a jak se metrika vyvinula. Kauzalitu netvrď, nabídni ji k prověření.

### BF8 Anomálie v událostech
**Z3.** Detekce: `list_events`, hledej opakující se chyby, nárazové skoky a přerušení. Události, které se opakují každý den, jsou nález i když je nikdo nečte.

### BF9 Osiřelé a duplicitní tagy, filtry a výběry
**Z3.** Detekce: `list_product_tags`, `list_product_filters`, `list_queries`, položky nepoužité v žádné strategii a položky se stejným obsahem pod jiným názvem. Stejná logika jako u výběrů v Mergadu.

### BF10 Záměna kanálu nebo země
**Z2.** Detekce: nastavení projektu proti kanálu (Heureka CZ, Heureka SK, Zboží) a proti měně a jazyku produktů. Bidding v CZK na SK kanálu je nález.

### BF11 Konkurenční data, na která se strategie odvolávají
**Z2.** Detekce: `list_competitors`, strategie limitované konkurencí nebo pozicí, ke kterým chybí aktuální konkurenční data. Bez nich se limit chová jinak, než autor zamýšlel.

### BF12 Rozpor s cenotvorbou
**Z1.** Detekce jen když je dostupný i Pricing Fox: strategie počítající s marží, která už neplatí, protože PF cenu mezitím změnil. Patří i do cross-app katalogu, tady jde o pohled z BF.
