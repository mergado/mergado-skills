# Detekce dostupnosti rozšíření

Cíl: zjistit, které oblasti se dají auditovat, a **žádnou nedostupnost neproměnit v chybu ani v tichý přeskok**. Výstupem je tabulka pokrytí, která jde do reportu.

Nedostupnost má pět různých příčin a report je musí rozlišovat, protože z každé plyne jiná akce pro uživatele:

| Příčina | Co to znamená | Zápis do pokrytí |
|---|---|---|
| MCP server není připojený | Nástroj neexistuje, `Unknown tool` i po opakování | `přeskočeno - MCP server není připojený` |
| Server je připojený, ale uživatel na eshop nemá práva | Nástroj odpoví, eshop nebo projekt ve výpisu není | `přeskočeno - eshop v tomto nástroji nedostupný (práva?)` |
| Rozšíření na projektu není zapnuté | Server odpoví, projekt existuje, ale žádná konfigurace v něm není | `přeskočeno - rozšíření na projektu není používané` |
| Rozšíření je nainstalované, ale nepoužívané | Aplikační pravidlo v Mergadu je aktivní, projekt v nástroji existuje, ale má **ověřeně** nulovou konfiguraci (0 pravidel, 0 strategií, 0 spárovaných produktů) | `nainstalováno, nepoužívá se` a **je to nález**, ne přeskočení |
| Rozhodl jsi se to neprovést | Rozpočet, `--skip`, nedostatek času. Není to vlastnost projektu ani nástroje. | `vynecháno` s uvedením, že šlo o rozhodnutí |

Nikdy nepiš `v pořádku` ani `bez nálezů` k oblasti, která se nezkontrolovala. A nikdy nevydávej vlastní rozhodnutí o rozpočtu za technickou nedostupnost, to je nejtišší způsob, jak report zkreslit.

**Probe a navázání projektu jsou povinné u každého rozšíření.** Je to čtyři až šest levných dotazů na celý audit. Neobcházej je odhadem z výpisu Mergado pravidel: to, že v projektu chybí aplikační pravidlo nějakého rozšíření, není důkaz, že rozšíření projekt nemá. Indicie z pravidel smí podezření jen vyvolat.

## Postup

### 1. Názvy serverů nejsou fixní

Stejné rozšíření může být napojené pod produkčním i dev názvem. Nespoléhej na jeden konkrétní název, projdi varianty:

| Oblast | Varianty prefixu nástrojů |
|---|---|
| Mergado | `mergado` |
| Pricing Fox | `pricing-fox`, `pricing-fox-dev` |
| Bidding Fox | `bidding-fox`, `bidding-fox-dev` |
| Feed Image Editor | `Feed Image Editor`, `Feed Image Editor Dev` |

**Ber produkční variantu.** Uživatelé mají napojené produkční servery, dev varianty jsou vývojové a slouží k internímu testování. Po dev variantě sáhni jen tehdy, když produkční napojená není vůbec a uživatel dev výslovně potvrdí. Do reportu vždy napiš, kterou variantu jsi použil, protože dev data nemusí odpovídat realitě klienta.

Když z aplikačních pravidel v Mergadu vidíš dev variantu (`apps.pricingfox.dev.pricing`, `apps.biddingfox.dev.inputrule`, `apps.feedimageeditor.dev.imageru`), zmiň to v reportu jako nález sám pro sebe: produkční projekt nemá běžet na dev aplikacích. Není to důvod přepínat audit na dev servery.

**Bidding Fox a Bidding Fox Elements jsou dvě různá rozšíření.** Pletou se, protože mají podobný název i společný prefix v aplikačních pravidlech, ale dělají jiné věci a instalují se samostatně.

| | Bidding Fox | Bidding Fox Elements |
|---|---|---|
| Co dělá | řídí CPC, tedy strategie a bidování | dodává do feedu data ze srovnávače jako elementy `BFE_*` |
| Aplikační pravidlo | `apps.biddingfox.inputrule` (dev: `apps.biddingfox.dev.inputrule`) | `apps.biddingfoxelements.datarule` (dev: `apps.biddingfoxelements.dev.datarule`) |
| Typ pravidla | zapisuje do elementu s CPC | `type: "app"`, plní jen elementy `BFE_*` |
| Vlastní MCP server | ano, `bidding-fox` | ne, nemá ho |
| Kam patří nálezy | katalog `kontroly-bidding-fox.md`, kódy `BF*` | katalog dat a konfigurace, protože se posuzuje z Mergada |

**Přítomnost elementů `BFE_*` ani pravidla `apps.biddingfoxelements.*` není důkaz, že na projektu je Bidding Fox.** Je to opačně velmi častá kombinace: eshop má nainstalovaná Bidding Fox Elements, aby měl výkonová data ve feedu k vlastním pravidlům, a bidování neřeší vůbec. Do tabulky pokrytí proto Bidding Fox Elements nepatří jako řádek Bidding Fox, a jejich přítomnost nesmí změnit stav toho řádku.

Rozliš to takhle:

- V `list_project_rules` hledej **pravidlo, které zapisuje do elementu s CPC**. Když tam je, řídí CPC Bidding Fox. Když v projektu je jen `apps.biddingfoxelements.*` a element s CPC má `origin: input` a nikdo do něj nezapisuje, **CPC neřídí nikdo** a to je nález G2b, ne nález Bidding Foxu.
- Stav řádku Bidding Fox v tabulce pokrytí urči vždy probem do `bidding-fox`, nikdy z existence elementů `BFE_*`.
- Když je v projektu Bidding Fox Elements a Bidding Fox ne, zmiň to v reportu jednou větou u G2b a nabídni Bidding Fox jako tip (ℹ️), protože data pro bidování už ve feedu jsou a chybí jen nástroj, který je použije.

**Elementy `BFE_*` mají být pro výstup skryté a normálně skryté jsou.** Bidding Fox Elements je zakládá s `is_hidden: true`, takže do výstupního XML nejdou. To je správné chování a **není to nález**: jsou to vstupní data pro pravidla, ne obsah pro srovnávač. Viz `co-neni-nalez.md`. Nálezem je až opačný stav, tedy `BFE_*` s `is_hidden: false`, protože pak do feedu odcházejí výkonová čísla eshopu (kontrola V5).

Pokud nástroje nejsou v kontextu vidět (deferred loading), zkus si je dotáhnout vyhledáním podle prefixu. Když se nedotáhnou, oblast je nedostupná.

### 2. Probe call na každou oblast

Použij nejlevnější čtecí nástroj a **na `Unknown tool` zkus právě jednou znovu** (dynamické načítání má cold start).

| Oblast | Probe | Nedostupné, když |
|---|---|---|
| Mergado | `get_current_user` | selže → audit nelze spustit vůbec |
| Pricing Fox | `ping`, pak `who_am_i` | nástroj neexistuje nebo probe selže |
| Bidding Fox | `ping`, pak `who_am_i` | nástroj neexistuje nebo probe selže |
| Feed Image Editor | `ping` | nástroj neexistuje nebo probe selže |

### 3. Navázání projektu v rozšíření

Probe říká jen to, že server žije. Teď zjisti, jestli v něm ten konkrétní projekt vůbec je.

**Feed Image Editor** používá stejné `project_id` jako Mergado. Zavolej `templates_list` s tímhle ID.
- Chyba nebo prázdný výsledek → FIE na projektu není používaný, přeskoč celou oblast.
- Seznam šablon → oblast je aktivní.

**Pricing Fox**: **začni `get_all_projects` s Mergado `shop_id` auditovaného eshopu** (parametr `shopId`) a v odpovědi najdi auditovaný projekt. Ověř `get_project_settings` na nalezeném ID.

  `get_all_shops` použij jen jako doplněk a **neber jeho výpis jako úplný**: vrací zkrácený seznam (ověřeno: 10 eshopů, všechny s `created_at` 2012-01-01) a nemá parametr stránkování, takže auditovaný eshop v něm klidně nebude, i když projekt v Pricing Foxu existuje. Kdo se rozhodne podle `get_all_shops`, přeskočí oblast, ve které jsou nálezy.
- Eshop ve výpisu není → přeskoč, důvod "eshop v PF nedostupný".
- Eshop je, projekt pro tenhle feed není → přeskoč, důvod "PF na projektu není používaný".

**Bidding Fox**: pozor, `get_all_shops` a `get_all_projects` tady vracejí ID, na která ostatní nástroje odpoví `Project not found`. Neber je jako pravdu.
- Postup: zkus `get_project_overview` s ID získaným z výpisu. Když odpoví `Project not found`, **nepovažuj to za důkaz, že projekt neexistuje**, ale za známou nekonzistenci ID.
- Zeptej se uživatele na ID projektu v Bidding Foxu, případně na to, zda BF na tomhle eshopu vůbec běží. Když odpověď nedostaneš nebo ji nemá, oblast přeskoč s důvodem "BF ID projektu se nepodařilo navázat (nekonzistentní ID ve výpisu)".
- Rozlišit „nástroj je rozbitý" od „tenhle projekt v něm není" jde tak, že stejný dotaz zkusíš na jiný projekt téhož eshopu. Když odpoví, nástroj funguje a chybí jen navázání konkrétního projektu. Nikdy neauditujte cizí ani testovací projekt místo toho, o který uživatel požádal.

### 4. Nezjišťuj instalované aplikace přes list_project_apps

`list_project_apps` a `get_project_app` vracejí přes MCP prázdno nebo 404 i u projektu, kde je aplikace v UI nainstalovaná. **Z jejich prázdné odpovědi nikdy nevyvozuj, že rozšíření není zapnuté.** Detekci dělej výhradně postupem výše, tedy dotazem do příslušného nástroje.

Nepřímá indicie, že nějaká aplikace do feedu zapisuje, je přítomnost jejích elementů nebo pravidel: `list_project_elements` a `list_project_rules`. Když v projektu vidíš pravidla nebo elementy zjevně vytvořené aplikací, ale její MCP není dostupné, zapiš to do reportu jako nezkontrolovanou oblast s poznámkou, že se v projektu používá.

**U té poznámky pojmenuj rozšíření přesně, ne podle prefixu elementu.** Elementy `BFE_*` patří Bidding Fox Elements, ne Bidding Foxu, a napsat k řádku Bidding Fox „rozšíření se používá, v projektu je 33 elementů `BFE_*`" je věcná chyba: může jít o projekt, kde Bidding Fox nikdy nebyl. Viz tabulka v sekci 1.

### 5. Chybějící elementy nejsou nález

Než pustíš kontrolu závislou na elementu (nákupní cena, původní cena, EAN, parametry), ověř, že element v `list_project_elements` existuje.

- Element chybí → kontrola se přeskočí s důvodem "element X v projektu není".
- Výjimka: u kontrol, kde je absence sama problémem (chybějící GTIN u brandovaných produktů pro Google Shopping, chybějící shipping), je absence nález. Tyhle kontroly jsou v katalozích výslovně označené.

## Výsledek fáze

Tabulka, kterou ukážeš uživateli před spuštěním kontrol a která jde do reportu:

```
| Oblast              | Stav          | Detail                                    |
|---------------------|---------------|-------------------------------------------|
| Mergado data        | k dispozici   | projekt 123456, formát Heureka XML        |
| Mergado konfigurace | k dispozici   | 47 pravidel, 12 výběrů                    |
| Provoz              | k dispozici   |                                            |
| Pricing Fox         | k dispozici   | pricing-fox (produkce), projekt 8821      |
| Bidding Fox         | přeskočeno    | ID projektu se nepodařilo navázat         |
| Feed Image Editor   | přeskočeno    | na projektu není používaný (0 šablon)     |
| Cross-app           | částečně      | bez BF a FIE, kontroly X3 a X8 vynechány|
```
