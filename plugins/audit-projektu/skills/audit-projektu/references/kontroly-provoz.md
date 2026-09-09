# Provozní a performance kontroly (Mergado)

Vstupní data: `get_import_logs`, `get_import_log`, `get_export_logs`, `get_export_log`, `get_apply_logs`, `get_access_logs`, `get_shop_event_logs`, `get_tariff`, `get_shop_info`, `list_pairings`, `list_shop_projects`, `get_user_notifications`.

Tahle sekce je "performance audit ze zkušenosti": nehledá chybu v jednom produktu, ale to, že projekt jako celek nefunguje tak, jak si někdo myslí.

### O1 Klesající počet produktů mezi importy
**Z1.** Detekce: `get_import_logs`, projdi historii a porovnej počty produktů. Skokový propad znamená, že se zdrojový feed láme nebo že dodavatel změnil strukturu. Uveď datum zlomu, ať se dá dohledat, co se tehdy dělo.
Pozor: sezónní pokles sortimentu je legitimní. Rozhoduje skok proti postupnému trendu.

### O1b Projekt drží jiný sortiment než jeho zdrojový feed
**Z1.** Detekce: počet produktů v projektu proti počtu, který dnes nabízí jeho **vstupní** feed. Číslo o zdroji ber z `get_import_logs` a `get_import_log` u posledního importu (zpracované, přeskočené a chybové položky) a přidej k němu čas toho importu a `is_dirty` z `get_project`. Nález je nevysvětlený rozdíl, tedy projekt drží výrazně méně produktů, než mu zdroj posílá, a přeskočené položky to nepokrývají.
Typická příčina je vypnutá automatická synchronizace nebo starý import: projekt i jeho export jsou zamrzlé na dřívějším stavu sortimentu, zatímco dodavatel už posílá jiná data. Do nálezu piš obě čísla, rozdíl, jeho podíl na zdroji a čas posledního importu.
Rozdíl proti sousedním kontrolám: `O1` porovnává importy mezi sebou, tedy trend v čase. `O6` porovnává projekt proti exportu, tedy co ubylo až za skrývacími pravidly a filtrem formátu. Tahle kontrola porovnává projekt proti jeho vstupu, tedy jestli má projekt vůbec aktuální data.
Když číslo z importních logů nedostaneš a vstupní adresa splňuje hranice pro stahování feedu z pravidla 1 v `SKILL.md`, smíš počet položek zjistit **jen počítáním v shellu** (třeba `grep -c` nad názvem produktového elementu), nikdy načtením feedu do kontextu. Takové číslo označ v reportu za zjištěné ze stahování.
Pozor na čtyři falešné závěry: u nově založeného nebo právě zkopírovaného projektu první plný import ještě proběhnout nemusel, projekt může být napojený na výstup jiného projektu místo na dodavatelský feed, u formátů s vnořenými variantami neodpovídá počet položek v XML počtu produktů v projektu, a zdrojový feed nikdy neporovnávej s tím výstupním.

### O2 Chybové a částečné importy
**Z1.** Detekce: importy se stavem chyby, nebo import, který skončil úspěšně s nulou zpracovaných produktů. Zvlášť hlídej data importy (Data File Import), u kterých se přes MCP tiše zahazuje párovací sloupec, takže "úspěšný" import nespáruje nic. Když v projektu takový import je, ověř podle dat, jestli hodnoty skutečně dosedly.

### O3 Rostoucí doba importu
**Z3.** Detekce: trend délky importů. Slouží jako předstih před tím, než import začne padat na timeout.

### O4 Zdrojový feed vrací chybu se stavem 200
**Z1.** Detekce: nepřímo z importních logů (nulový nebo absurdně nízký počet produktů při úspěšném stažení). Typicky eshop místo feedu vrací HTML chybovou stránku nebo přihlašovací formulář.

### O5 Stáří exportu
**Z1.** Detekce: `get_export_logs`, čas posledního exportu proti frekvenci, se kterou platforma feed stahuje. Když se export negeneruje, platforma jede na starých cenách a dostupnostech, což je nejdražší možná chyba.

### O5b Feed si nikdy nestáhl žádný cizí klient
**Z1.** Detekce: `get_access_logs` a `get_access_log`, podívej se na `user_agent` jednotlivých přístupů. Když jsou všechny přístupy interní (typicky MergadoBot) a žádný nepatří cílové platformě, **feed se generuje do prázdna**.
Potvrzující signály, které stojí za to složit dohromady: nulové náklady a prokliky v elementech od rozšíření, vypršelý tarif nebo `readonly` projekt z fáze 0, a chybějící napojení na reklamní systém daného kanálu.
**U napojení si ověř, co pro ten kanál dnes platí.** U projektů pro Zboží.cz je relevantní **Sklik Fénix**; klíč pro Zboží.cz v Keychainu je stará metoda a jeho absence nález není. Naopak chybějící napojení na Sklik Fénix u takového projektu nález je. Viz `co-neni-nalez.md`.
Proč to vadí: je to jediná kontrola, která dává smysl celému zbytku auditu. Bez ní popíšeš dvacet nálezů jako „poškozuje výkon kanálu", zatímco ten kanál vůbec neinzeruje, a klient řeší priority podle špatné mapy. Proto ji dělej hned po provozních kontrolách a její výsledek zmiň v Souhrnu.
Pozor na dva falešné závěry: platforma může feed stahovat mechanismem, který se do přístupových logů nepropíše, a u nového projektu ještě stahovat nemusela začít. Formuluj tedy nález jako „podle přístupových logů si feed nestáhl žádný cizí klient" a doplň, jak je projekt starý.

### O6 Rozdíl mezi počtem produktů v projektu a v exportu
**Z2.** Detekce: počet produktů projektu proti počtu v posledním exportu. Rozdíl vysvětli: skrývací pravidla (viz konfigurace R9), filtr formátu, nebo chyba. Nález je nevysvětlený rozdíl.

### O7 Duplicitní projekty pro stejnou platformu
**Z2.** Detekce: `list_shop_projects`, dva projekty se stejným výstupním formátem a stejnou zemí. Zjisti, který z nich je skutečně nasazený u platformy, a upozorni na to, že se úpravy dělají možná v tom druhém.

### O8 Zapomenutý projekt
**Z3.** Detekce: `get_access_logs`, kdy do projektu naposled někdo vstoupil, proti tomu, že export dál běží. Projekt, do kterého rok nikdo nešel a který přitom utrácí rozpočet, si zaslouží revizi.

### O9 Blížící se limit tarifu
**Z2.** Detekce: `get_tariff` a `get_shop_info` proti skutečnému počtu produktů napříč projekty.

### O10 Nespárované produkty
**Z2.** Detekce: `list_pairings` a `get_pairing`. Nespárované produkty znamenají chybějící metriky a párování je předpokladem většiny rozšíření.

### O11 Ignorované notifikace
**Z3.** Detekce: `get_user_notifications`, nepřečtené nebo opakující se varování. Když Mergado už měsíc hlásí problém a nikdo ho nečte, patří to do reportu.

### O12 Podezřelá aktivita v historii eshopu
**Z3.** Detekce: `get_shop_event_logs`, nárazové hromadné změny. Užitečné k dohledání, kdy se projekt rozbil a čí změna to byla. Piš to věcně jako časovou souvislost, ne jako obvinění konkrétního člověka.
