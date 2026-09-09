# Kontroly Feed Image Editor

**Spouštěj jen když `templates_list` na `project_id` projektu vrátil aspoň jednu šablonu.** Prázdný výsledek znamená, že FIE na projektu není používaný, a sekce se přeskočí.

`project_id` je stejné jako ID projektu v Mergadu. Výběry v šablonách (`queries`) jsou ID Mergado výběrů, takže se dají křížit s katalogem konfigurace.

Vstupní data: `templates_list`, `templates_detail`, `templates_layers_list`, `templates_get_size`, `templates_get_status`, `templates_visual_similarity`, `sizes_list`.

Nikdy nevolej `templates_create`, `templates_delete`, `templates_rename`, `templates_duplicate`, `templates_reorder`, `templates_layers_create`, `templates_layers_reorder`, `templates_set_activity`, `templates_set_size`, `templates_set_ai_type`, **`templates_ai_params`**, `templates_copy_from_project_to_project`, `custom_images_upload`. Smazání šablony je nevratné.

**`templates_ai_params` navzdory názvu AI obohacování zapíná a vypíná, nečte jeho stav.** Stav je v poli `ai_params_enabled` odpovědi `templates_detail`.

V reportu cituj šablony názvem i ID, například `„odpočet 🚀" (ID 1089)`. Vede text názvem, ID je pro dohledání.

### FIE1 Šablona s prázdným výběrem
**Z2.** Detekce: pro každou šablonu vezmi její `queries` a ověř počet produktů v Mergadu (`query_products` s `limit: 1`, čti `total_results`). Nula znamená, že šablona negeneruje nic, přitom se s ní počítá.

### FIE2 Šablona odkazující na neexistující výběr
**Z1.** Detekce: `queries` šablony obsahují ID, které v `list_project_queries` není. Typicky po smazání výběru v Mergadu. Šablona pak nemá na čem pracovat.

### FIE3 Překrývající se šablony a jejich priorita
**Z2.** Detekce: dvě šablony, jejichž výběry mají průnik. O výsledku rozhoduje pořadí v `templates_list`. Uveď, které produkty jsou v průniku a která šablona je v pořadí první, ale netvrď víc, než co pořadí říká.

### FIE4 Dlouho vypnuté šablony
**Z3.** Detekce: šablony s nastavenou neaktivitou. Uveď je jako kandidáty na úklid.

### FIE5 Prošlá sezónní akce v layeru
**Z2.** Detekce: `templates_layers_list` a textové layery obsahující sezónní nebo akční sdělení ("Black Friday", "Vánoční sleva", "Letní výprodej", konkrétní rok). Porovnej s aktuálním datem. Aktivní šablona, která v květnu vypaluje do obrázků Black Friday, je obrázkovou verzí zimního výprodeje v létě.

### FIE6 Cena nebo sleva vypálená do obrázku
**Z1.** Detekce: textové layery s číselnou cenou, procentem slevy nebo částkou. Obrázek se neaktualizuje s feedem, takže se dřív nebo později rozejde s reálnou cenou. Když se dá porovnat s cenou produktů z výběru, ověř rozpor a nahlas ho jako právní i důvěryhodnostní riziko (stejná rodina jako Omnibus nález A5).

### FIE7 Overlay text ve feedu pro Google
**Z1.** Podmínka: cílový výstupní formát projektu je Google Shopping nebo obdobný.
Detekce: šablony s textovými layery nebo grafickými odznaky u produktů, které jdou do Googlu. Google promo overlay v obrázcích odmítá, takže výsledkem je zamítnutí produktů, ne jen kosmetika.
Pozor: rozliš cílové kanály. Pro Heureku nebo Meta reklamu může být overlay v pořádku. Když jde jeden FIE výstup do víc kanálů, je to samo o sobě nález.

### FIE8 Nepodporovaný nebo nevhodný rozměr
**Z3.** Detekce: `templates_get_size` a `sizes_list` proti požadavkům cílové platformy (minimální rozměr, poměr stran). Malý nebo nestandardní rozměr vede k odmítnutí obrázku.
Pozor: chyba `Template size for template <id> not found` **není závada**. Šablona s `is_keep_size: 1` si drží rozměr originálu a vlastní velikost nemá.

### FIE9 Obrázek nesouvisí s produktem
**Z2.** Detekce: `templates_visual_similarity` a vzorek produktů z výběru šablony, porovnej s názvem produktu. Nálezy: obrázek jiné varianty, obrázek příslušenství, obrázek celé kolekce místo jednoho produktu.

### FIE10 AI atributy bez využití
**Z3.** Detekce: pole `ai_params_enabled` a typ AI z `templates_detail` proti tomu, jestli se výstupní atributy někde v Mergadu používají (element existuje a je naplněný, nějaké pravidlo ho čte). Zapnutá AI, jejíž výstup nikam neteče, je jen náklad.

### FIE11 Neúspěšné nebo zaseknuté zpracování
**Z2.** Detekce: `templates_get_status`, šablony ve chybovém stavu nebo dlouho nedokončené. Produkty pak mají v exportu původní neupravené obrázky, případně žádné.
