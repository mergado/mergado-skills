# Kontroly Pricing Fox

**Spouštěj jen když detekce potvrdila, že PF je dostupný a projekt v něm existuje.** Jinak celou sekci přeskoč a zapiš do pokrytí.

Vstupní data: `get_project`, `get_project_settings`, `get_project_settings_history`, `list_rules`, `get_rule_history`, `list_competitors`, `get_competitor`, `list_products`, `get_product`, `get_product_history`, `list_imports`, `get_import`, `list_exports`, `get_export`, `list_connectors`, `get_insights`, `get_project_metrics`, `get_report_top_products`, `get_report_flop_products`, `list_product_filters`.

Nikdy nevolej `create_rule`, `edit_rule`, `clone_rules`, `pause_rules`, `start_rules`, `reorder_rules`, `pause_import`, `start_import`, `regenerate_export`, `enable_connector`, `disable_connector`, `watch_competitor`, `unwatch_competitor`. Audit je read-only. (Poznámka: PF ani nemá `delete_rule`, takže omyl by se hůř vracel.)

### PF0 Nainstalovaný, ale nenastavený Pricing Fox
**Z2.** Detekce: aplikační pravidlo Pricing Foxu v Mergadu je aktivní, ale `list_rules` vrací prázdno, `paired` je 0 a `priced` je 0 (metriky v `get_project`). Doplň, co chybí v nastavení: `purchase_price_element`, `vat_element`, `item_id_element`, validátory `validators_too_cheap` a `validators_too_expensive`, stav konektorů.
Proč to vadí: aplikace běží v řetězci pravidel a nic nedělá, přitom se na ni někdo spoléhá. Bez `purchase_price_element` navíc nelze hlídat marži, takže první pravidlo, které kdo vytvoří, poběží bez dolního limitu (viz PF2).
Pozor: `get_project` může vrátit stovky kB. Když odpověď nejde zpracovat, načti ji po částech a čti jen `project_settings`, `checks` a poslední řádek `metrics`.
Pozor 2: `checks.possible_errors` je **katalog kontrolovatelných kódů**, ne seznam nalezených chyb. Skutečné nálezy jsou v `checks.errors`. Prázdné `errors` znamená, že PF žádnou chybu nehlásí.

### PF1 Cena pod nákupní cenou nebo pod minimální marží
**Z1.** Detekce: **`list_rules` a v odpovědi `latest_metrics` u každého pravidla.** Žádné stahování produktů není potřeba, Pricing Fox to hlásí sám. Klíčové hodnoty:

| Klíč | Co znamená |
|---|---|
| `new_price_below_purchase_price` | kolik produktů pravidlo přecenilo pod nákupní cenu |
| `input_price_below_purchase_price` | kolik jich pod ní bylo už na vstupu (to není vina pravidla) |
| `margin_min`, `margin_avg` | negativní minimum je nález. Marže shodná u všech produktů je podezření na vymyšlenou nákupní cenu, viz X10 v katalogu cross-app |
| `applied_margin_limit` | kolikrát se limit marže uplatnil |
| `diff_price_sum` | celkový dopad na cenovou základnu, nejsrozumitelnější číslo pro klienta |

**Nula v `applied_margin_limit` u pravidla, které má nastavený `margin_limit_min` a zároveň nenulový `new_price_below_purchase_price`, znamená, že limit nedrží.** To je samostatný nález a je vážnější než jednotlivé produkty, protože pojistka, na kterou se někdo spoléhá, nefunguje.

### PF2 Pravidlo bez dolního limitu
**Z1.** Detekce: u každého pravidla z `list_rules` zkontroluj `margin_limit_min`, `margin_limit_max`, `manual_limit_min_price`, `costs_limit_min`.

Dvě pasti:
- **`margin_limit_min: 0` není ochrana.** Povoluje nulovou marži, a jak ukazuje PF1, nemusí ji vynutit ani tu.
- **Absolutní srážka** (`diff_type: absolute`) u levného sortimentu spolkne marži celou. Pravidlo „být nejlevnější o 10 Kč" znamená u produktu za 30 Kč něco úplně jiného než u produktu za 3000 Kč. Porovnej `diff_value` s `new_price_min` v metrikách.

Dále zkontroluj `apply_to` a `is_on_all_mergado_query`: pravidlo s `apply_to: "all"` cenotvoří celý feed, i když jeho název mluví o segmentu.

### PF3 Konfliktní a duplicitní pravidla, špatné pořadí
**Z2.** Detekce: pravidla se stejnou podmínkou a různým výsledkem, pravidla, kde pozdější plošně přepisuje dřívější, a pravidla, jejichž pořadí neodpovídá zamýšlené logice (specifické až po obecném). Pozor na zápis podmínek přes Mergado elementy: v PF se podmínka na element skládá typem, který nese název elementu, takže si formu podmínky ověř na existujícím pravidle, než ji začneš vyhodnocovat.

### PF4 Pravidlo, které nikdy na nic nesedne
**Z2.** Detekce: pravidlo s nulovým počtem zasažených produktů. Ověř přes produkty a filtry, ne odhadem.

### PF5 Nefunkční nebo zastaralý konkurent
**Z2.** Detekce: `list_competitors` a `get_competitor`, hledej konkurenty bez dat za posledních X dní. Pravidla, která na nich stojí, pak počítají z posledních známých cen nebo nedělají nic.

### PF6 Konkurent, který nemá být referencí
**Z1.** Detekce: konkurent se systematicky výrazně nižšími cenami (bazar, šedý dovoz, výprodejce, marketplace s jiným rozsahem služby) použitý v pravidlech, která ho následují dolů. Uveď medián odchylky, ať je argument doložený.

### PF7 Špatné párování s konkurencí
**Z1.** Detekce: vzorek produktů a jejich napárovaných konkurenčních produktů, AI porovná názvy a posoudí, jde-li o tentýž produkt. Nálezy: jiná varianta, jiné balení, jiná kapacita, příslušenství místo produktu. Cenotvorba proti špatně napárovanému produktu je nejtišší způsob, jak ztrácet marži.

### PF8 Pozastavený import ceníku
**Z1.** Detekce: `list_imports` a `get_import`, pozastavený nebo dlouho neproběhlý import nákupních cen či konkurenčních dat, zatímco pravidla dál běží nad starými čísly.

### PF9 Oscilace ceny
**Z2.** Detekce: `get_product_history`, produkty s vysokou frekvencí změn ceny nebo se střídáním dvou hodnot. Znamená to dvě pravidla, která si přehazují produkt mezi sebou. Uveď konkrétní produkty a obě hodnoty.

### PF10 Export se negeneruje
**Z1.** Detekce: `list_exports` a `get_export`, stáří posledního exportu. Ceny spočítané a neodeslané jsou k ničemu.

### PF11 Vypnutý konektor, se kterým pravidla počítají
**Z2.** Detekce: `list_connectors` proti tomu, na jaká data se pravidla odkazují.

### PF12 Změna nastavení, po které se metriky zhoršily
**Z2.** Detekce: `get_project_settings_history` a `get_rule_history` v korelaci s `get_project_metrics` a `get_insights`. Hledáš časovou souvislost mezi změnou konfigurace a zlomem v metrikách. Formuluj jako souvislost k prověření, ne jako prokázanou kauzalitu.

### PF13 Zaokrouhlení, které sráží marži
**Z3.** Detekce: pravidla zaokrouhlující dolů na psychologickou hranici u produktů s nízkou marží. U levného sortimentu může zaokrouhlení spolknout celý zisk.
