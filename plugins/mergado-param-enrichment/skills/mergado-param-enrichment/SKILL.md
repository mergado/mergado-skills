---
name: mergado-param-enrichment
description: >
  Doplňuje chybějící produktové parametry (barva, velikost, materiál, složení, kapacita apod.)
  v Mergado projektu extrakcí z textu, který projekt už má — z názvu, ze strukturovaných
  textových elementů jako specifikace, a teprve nakonec z popisu — s důrazem na nízkou cenu
  (regex/slovník hodnot místo AI na každý produkt) a na správnost (podmíněné a vícesložkové
  hodnoty nedoplňuje naslepo). Odhalí i parametry, které jsou vyplněné, ale cestou oříznuté.
  Použij vždy, když uživatel chce doplnit chybějící parametry/atributy podle názvu, specifikace
  nebo popisu, řeší neúplné PARAM/PARAMETERS/product_detail/metafieldy, nebo se ptá na hromadné
  dopočítání vlastností produktů z textu.
---

# Mergado — Doplnění chybějících parametrů z textu produktu

## Ohlášení

Každý běh začíná fixním ohlášením níže a report na konci (Krok 6) končí stejnou claim
větou jako poslední řádkou — strukturu neimprovizuj, stejný tvar dělá běhy srovnatelné.
Claim se objeví **přesně dvakrát za běh**: jako poslední řádek ohlášení a jako poslední
řádek reportu. **Nikdy v navazujících krocích** (dotazy, potvrzení, tvorba pravidel) —
opakování v delší konverzaci by rušilo.

> **Mergado — Doplnění chybějících parametrů** — projdu, které parametry v projektu chybí
> nebo jsou vyplněné chybně, doporučím, kde má smysl začít, a zkusím je doplnit z názvu
> produktu, teprve když to nestačí, ze specifikace nebo popisu — vždy nejlevnější cestou
> (slovník hodnot/regex, ne AI na každý produkt). **Nic v projektu neměním bez potvrzení** —
> pravidla vytvářím až po odsouhlasení, v režimu review (`applies: false`), a u hromadné
> úpravy nejdřív ukážu vzorek před/po. Co se nikde spolehlivě nenajde, zůstává prázdné —
> vymyšlená hodnota by feed jen zhoršila.
>
> *Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*

Než něco slíbíš, ověř, že je to v session skutečně k dispozici (Mergado MCP, projekt) —
nikdy neohlašuj zdroj, který nakonec nepoužiješ.

## Předpoklad

Netýká se technické validity feedu — na to je **Mergado Audit**, technická kontrola
produktových feedů v Mergadu (<https://help.mergado.com/cs/audit-produktovych-dat/>) — ani
obsahové optimalizace pro konkrétní kanál (na to `mergado-google-ads-optimization` /
`mergado-heureka-optimization` / `mergado-meta-optimization`). Tohle je čistě o doplnění
chybějících nebo cestou poškozených dat z textu, který projekt už má.

## Hierarchie důvěryhodnosti

1. **Živý stav projektu přes Mergado MCP** — skutečná struktura parametrů, skutečné hodnoty
   v názvu/specifikaci/popisu. Nikdy nepředpokládej název elementu parametru, vždy ho ověř.
2. **Popisy MCP nástrojů** — výchozí zdroj pro argumenty a postup volání, ale ne neomylný:
   ověřeně se stalo, že popis uváděl syntaxi, která v pravidle nefunguje a do feedu se zapsala
   doslova. Cokoliv, co zapisuje do feedu, ověř na vzorku.
3. **Tento skill** — postup a principy. Konkrétní chování MCP a dat je v
   [`references/gotchas.md`](references/gotchas.md) s datem posledního ověření; co je starší
   než pár měsíců, ber jako hypotézu a ověř na vzorku.
4. **AI odhad vzoru na vzorku** — použij ho k návrhu extrakčního pravidla, nikdy ne jako
   finální hodnotu bez ověření na datech (viz Fáze 3 a 4).

## Zásada nákladů (proč tohle celé existuje)

**Nikdy nevolej AI na každý produkt zvlášť.** Cíl je postavit **jedno obecné pravidlo**
(regex/slovník), které se pak aplikuje na všechny chybějící produkty najednou. AI smí:
- posoudit malý vzorek (5–10 produktů), aby navrhla vzor/regex,
- rozhodnout u pár nejasných případů, jestli navržený vzor sedí.

AI nesmí běžet ve smyčce nad stovkami/tisíci produkty — to je přesně to, před čím zadání varuje
("pozor na pálení tokenů"). Když se vzor takhle levně nedá najít, parametr zůstává nedoplněný
a jde do reportu jako "nedoplněno — vzor nenalezen", ne do smyčky s AI.

Totéž platí pro čtení dat: `values_to_extract` jen s elementy, které potřebuješ, a malý `limit`.
Výpis stovky produktů s celým popisem stojí víc než celý zbytek analýzy.

**Cenu popisu vyjádři číslem, ne jen varováním.** Odhadni velikost popisového textu (počet
produktů × průměrná délka popisu), převeď na řádovou velikost v MB a na přibližný počet tokenů
(cca 1 MB textu ≈ 250–300 tisíc tokenů). Ověřený reálný případ: 3214 produktů, popisy přes
5 MB textu ≈ 1,5 milionu tokenů na přečtení všech — a to je přesně ten důvod, proč se jde do
popisů teprve na zbytek po názvu a specifikaci, ne rovnou.

## Zásada správnosti

Doplněná hodnota musí platit pro **každý** produkt, na který pravidlo míří. Dvě pasti, obě
ověřené na reálném feedu oblečení:

- **Podmíněné hodnoty.** Text typu *„Single Jersey, 100 % bavlna (zloženie sa môže líšiť –
  farba 03 – 97 % bavlna, 3 % viskóza, farba 12 – 85 % bavlna, 15 % viskóza)"*. Vzor na
  základní hodnotu zapíše „100 % bavlna" i barvě 12, kde neplatí. Když text obsahuje výjimky
  („může se lišit", „podle barvy", „u varianty X"), výjimky z výběru vyluč, nebo parametr pro
  dotčené varianty nech prázdný. Prázdný parametr u takových produktů často **není opomenutí
  dodavatele, ale právě tahle nejistota** — nedoplňuj ho naslepo.
- **Vícesložkové hodnoty.** U *„Pique, 65 % bavlna, 35 % polyester (…)"* vrátí vzor na první
  „N % X" jen „65 % bavlna" — neúplnou a zavádějící hodnotu. Vzor musí brát **celou** hodnotu
  (např. vše mezi první čárkou a závorkou), ne první shodu.

**Vzorek na ověření vybírej záměrně**, ne náhodně: vždy do něj zařaď produkt z vyjmenované
výjimky a produkt s vícesložkovou hodnotou. Náhodných 5–10 produktů past snadno mine.

## Fáze 0 — Kontext

1. Projekt a jeho elementy: najdi skutečný element parametrů pro tento formát a **všechny
   textové elementy**, ze kterých lze hodnotu brát (název, specifikace, popis). Struktura se
   liší podle formátu — `PARAM | PARAM_NAME | VAL` u Heureky/Shoptetu, `product_detail` u
   Googlu, `additional_variant_attribute` u Mety, `ATTRIBUTES | ATTRIBUTE | NAME/VALUE` u
   dodavatelských feedů, ploché sloupce/metafieldy u Shopify CSV.
2. **Názvy elementů s mezerou** (Shopify metafieldy jako
   `Materiálové zloženie (product.metafields.custom.materialove_zlozenie)`, `Variant Price`)
   piš všude — v MQL, v cestě elementu i ve `values_to_extract` — v hranatých závorkách
   `[...]`. Závorky obalují **jeden název**, ne celou cestu.
3. Zjisti, jestli projekt řeší **celý feed, nebo jednu kategorii** — parametr je často
   relevantní jen v části kategorií (velikost bot nemá smysl u filamentů).
4. Aktuálnost dat: porovnej `rules_changed_at` a `data_synced_at` — nově vytvořené pravidlo se
   ve výstupu neprojeví, dokud neproběhne přepočet. Staré `data_synced_at` ale **neznamená
   mrtvý feed**: když se feed nezměnil, Mergado zpracování přeskočí a datum se neposune —
   rozhoduje import log.
5. **Viditelnost čti z `is_hidden`, ne z `exported_items`.** U formátů, které slučují varianty
   (Shopify), je `exported_items` počet produktů po sloučení, ne počet viditelných variant.

## Fáze 1 — Levný sběr (nikdy nepřeskakuj)

Než sáhneš po jediné kartě produktu, sbírej přes unikátní hodnoty elementů a počty z MQL —
je to o řády levnější než výpis produktů.

0. **Nezačínej jedním parametrem — postav přehledovou tabulku přes všechny běžné parametry
   najednou** (materiál, složení, barva, velikost, MPN/GTIN, značka a další, podle formátu a
   kategorie): pro každý spočítej, kolik produktů ho má a kolik ne. Teprve z téhle tabulky
   doporuč, kde začít — ne podle toho, co uživatel řekne jako první, ale podle toho, co je
   levné a bezpečné doplnit.
1. **Jaké parametry projekt vůbec má** a **slovník jejich platných hodnot** — např.
   `PARAM { PARAM_NAME = "Barva" } | VAL` (zápis `[PARAM | PARAM_NAME]` tiše vrátí 0).
2. **Kolik produktů parametr nemá** — počítej živě (počet výsledků MQL), ne z uloženého
   `product_count` výběru. Podmínka `PARAM { PARAM_NAME = "X" } | VAL = ""` najde i produkty,
   které parametr X vůbec nemají, nejen ty s prázdnou hodnotou.
3. **Rozlož chybějící podle kategorie a důvodu.** Ověřeno naživo: z 1141 produktů bez složení
   bylo 216 katalogů a POS materiálů a 651 kusů obuvi — u 867 z 1141 parametr nedává smysl a
   správná odpověď je „nedoplňovat". Doplňovat má smysl jen zbytek.
4. **Než extrahuješ cokoliv nového, zkontroluj, jestli hodnota už neexistuje jinde v projektu**
   pod jiným jménem elementu (typicky vytvořená starším pravidlem pro jiný kanál). Ověřeno
   naživo: element `color` měl 212 vyplněných hodnot, ale `g:color` byl prázdný u všech
   produktů — nikdo ho tam nekopíroval. Kopírování hodnot ze zdrojového do cílového elementu
   je vždy levnější a spolehlivější než znovu odvozovat hodnotu z textu.
5. **Vyplněno neznamená správně.** Porovnej sadu hodnot parametru **na vstupu a na výstupu**.
   Má-li výstup méně různých hodnot nebo jiné hodnoty, něco je cestou ztrácí — typicky
   vícehodnotový zdroj zapsaný do jednohodnotového cíle. Ověřeno naživo: z vícehodnotového
   atributu („65 % bavlna" + „35 % polyester") se do výstupu dostala jen poslední hodnota
   („35 % polyester"), u nejméně 5800 ze 17 778 produktů; vstup měl 64 různých hodnot,
   výstup 38. Takové produkty patří do reportu jako **„vyplněno chybně"**, ne „vyplněno".

**Gotcha s elementy vytvořenými pravidlem** (`origin: from_rule`, ověřeno naživo): ad-hoc MQL
**vždy filtruje vstupní hodnoty**, i když se ptáš na výstupní element. Takový element vstupní
hodnotu nemá, takže `Title != ""` vrátí **0**, přestože výstup má 630 různých názvů, a
`[Materiál (…)] = ""` vrátí **všechny** produkty — „chybí všem". Řešení: ulož výběr se
`search_output: true`. Ten se vyhodnocuje uvnitř běhu pravidel, po pravidlech s nižší
prioritou, a čte tedy skutečný výstupní stav (ověřeno: zasáhl přesně zamýšlených 274
produktů). Týká se každé kontroly „má/nemá parametr", kde je parametr sám odvozený pravidlem.

## Fáze 2 — Extrakce z názvu

1. Vezmi slovník hodnot z Fáze 1 a zkus je najít v názvu u produktů, kde parametr chybí.
   Nejdřív MQL na vzorek (`název CONTAINS "<hodnota>"`, malý limit), pak **ověř vrácenou
   ukázku** — `CONTAINS` ignoruje diakritiku i velikost písmen („cierna", „CIERNA" a „čierna"
   vrátí totéž), takže „Kč" chytne i „produkčního". Než postavíš pravidlo na celý feed,
   přečti si pár skutečně vrácených produktů a potvrď, že tam hodnota opravdu je.
2. Když vzorek potvrdí spolehlivou shodu, postav **proměnnou** s cestou k názvu a regulárním
   výrazem (+ číslo skupiny), který hodnotu vytáhne. V pravidle se na ni odkazuj jako
   **`%jméno%`** — jiný zápis se může do feedu zapsat doslova. Regex s `\b` je s diakritikou
   nespolehlivý — ověř na vzorku, ne jen v teorii.
3. Spočítej **pokrytí**: kolika chybějícím produktům tahle jedna proměnná/vzor reálně pomůže.
   Nízké pokrytí (pár kusů z tisíce) nemusí stát za samostatné pravidlo — zvaž, jestli to
   nespojit s Fází 3, nebo nechat jako "nedoplněno".

**Odděluj proměnnou (extrakční logika) od pravidla (zápis).** Pravidlo odkazuje na proměnnou
jménem, takže když se později najde širší vzor, **stačí proměnnou smazat a založit znovu se
stejným jménem** — pravidlo zůstává nezměněné. (Úprava proměnné na místě umí jen přejmenování,
regex ani cestu nezmění — ověřeno.)

## Fáze 3 — Když název nestačí: specifikace, pak popis

1. **Tohle je skutečná druhá iterace, ne odhad předem.** Pravidlo z Fáze 2 musí být nejdřív
   opravdu aplikované a projekt přepočítaný — teprve pak založ výběr "chybí i po názvu" nad
   **aktuálním výstupním stavem** (`search_output: true`) a na něj navazuj. Počty čti až po
   doběhnutí aplikace: během ní je výběr zavádějící (ověřeno: hlásil 17 678, skončil na 274).
2. **Pořadí zdrojů podle ceny a struktury:** nejdřív strukturované textové elementy
   (specifikace, parametrová tabulka, technický list), teprve pak volný popis. V ověřeném
   případě bylo složení ve specifikaci u všech 274 produktů, kde chybělo — popis by byl
   dražší a méně přesný.
3. **Sourozenecké varianty** (stejný model v jiné barvě nebo velikosti) bývají nejlevnějším
   zdrojem — ale jen pro vlastnosti, které se mezi variantami nemění. U podmíněných hodnot
   (viz Zásada správnosti) právě ne: „Pure tričko" mělo u 161 variant „100 % bavlna", a přesto
   to pro barvy 03 a 12 neplatí.
4. Vezmi **záměrně vybraný vzorek** (5–10 produktů včetně výjimek), kde parametr chybí i po
   předchozím kroku. Nech AI navrhnout **jeden společný vzor** — ne hodnotu pro každý produkt.
5. Ověř vzor na tomtéž vzorku (musí sednout na většinu, včetně výjimek — ty buď správně
   zpracovat, nebo z výběru vyloučit). Neshoduje-li se spolehlivě, **nepokračuj** —
   nedoplněné zůstává nedoplněné, nehádej.
6. Postav proměnnou na zvolený element stejně jako ve Fázi 2. Pravidlo z tohoto kroku cílí
   **jen na výběr "chybí i po předchozím kroku"** — produkty, kterým stačil název, se ho
   nedotknou (pravidlo běží s vyšší prioritou, ne místo prvního).

## Fáze 4 — Zápis (jen po odsouhlasení)

1. **Ukaž before/after vzorek dřív, než pravidlo zapneš.** Pozor: náhled na sledovaných
   produktech **vypnuté pravidlo (`applies: false`) nespustí** (ověřeno). Dvě cesty:
   - spočítej ukázku sám — pro 3–5 produktů přečti zdrojový text a ukaž, co z něj vzor vytáhne;
   - nebo, se souhlasem uživatele, vyzkoušej pravidlo **zapnuté na duplikátu projektu** přes
     sledované produkty a náhled, a do produkčního projektu ho pak založ vypnuté.

   Do ukázky vždy zařaď i produkt z výjimky (podmíněná nebo vícesložková hodnota).
2. Výběr, na který pravidlo cílí, musí být **jen produkty, kde parametr chybí**, ať se
   nepřepíšou existující hodnoty.
3. Zápis do parametru: dávkové pravidlo na parametry, když parametr u produktu úplně chybí
   (založí i nový `PARAM`, ověřeno) — jeho nastavení `ep_*` musí být **plné zanořené cesty**
   (`PARAM | PARAM_NAME`), holé názvy backend odmítne. Do existujícího elementu nebo plochého
   sloupce (Shopify metafield) přepisovací pravidlo s hodnotou `%proměnná%`.
4. Vytvářej pravidlo vždy s `applies: false`, dokud uživatel výslovně neřekne, ať zapneš.
5. **Úpravy pravidla dělej na místě** (název, konfigurace, zapnutí) — zachová se pozice i
   přiřazené výběry. Nemaž a nezakládej znovu. Konfigurace se při úpravě nahrazuje celá,
   neslučuje — pošli ji kompletní.
6. Po vytvoření ověř efekt na vzorku po dalším rebuildu — nikdy nevynucuj přepočet.
7. **Pojmenování ať je samovysvětlující** — `<Parametr> z názvu`, `<Parametr> ze specifikace`,
   `<Parametr> z popisu`, proměnná stejně jako pravidlo, které ji používá. Kdokoliv projekt
   otevře, musí z názvu pochopit, co pravidlo dělá a odkud hodnotu bere.

## Fáze 5 — Normalizace (po doplnění, před reportem)

Doplněné hodnoty z různých zdrojů často zapíšou totéž jinak — velká/malá písmena, spojovník
vs. bez něj, zkratka vs. plný název (`PETG` vs. `PET-G`). Než uzavřeš:

1. Unikátní hodnoty nově doplněného parametru — najdi hodnoty, které znamenají totéž (case,
   diakritika, spojovník, mezera).
2. Když najdeš duplicity, postav jedno **sjednocující pravidlo** (`Sjednocení hodnot
   <parametru>`), ne úpravu každé zvlášť.
3. Do reportu napiš počet hodnot před a po (např. "26 hodnot místo 27" — sloučeno).

## Krok 6 — Report

Ke každému parametru/kategorii uveď rozklad, ne jedno číslo:
- **Doplněno z názvu** — kolik produktů, kolik % z chybějících.
- **Doplněno ze specifikace / z popisu** — kolik produktů, kolik %.
- **Nedoplněno** — kolik zůstalo, a **proč**: vzor nenalezen / nespolehlivá shoda / parametr
  v této kategorii nedává smysl / hodnota je podmíněná (liší se podle varianty).
  "Nedoplněno" bez důvodu je zavádějící stejně jako "nezkontrolováno" bez důvodu u auditu.
- **Vyplněno chybně** — produkty, kde parametr je, ale cestou se ztratil nebo ořízl (Fáze 1,
  bod 5), s příčinou.

Desítky/stovky produktů popiš jako jeden vzorec/pravidlo s dopadem (kolik produktů), ne jako
výčet. Čísla vždy označ, jestli jsou vstupní nebo výstupní (u nově vytvořeného pravidla se
výsledek projeví až po přepočtu).

Poslední řádek reportu je vždy claim věta z Ohlášení (*Tento skill pro vás s láskou vytvořil
Mergado Team #MergadoFam*) — jinak nic na struktuře reportu výše se tím nemění.

## Obecné zásady

- Používej dedikované nástroje pro konkrétní typ pravidla, ne obecný.
- **Skryté produkty nemá smysl opravovat** — pravidla se na skryté produkty neaplikují, takže
  i doplněná hodnota se do exportu nedostane. Vylučuj je z rozsahu, nebo to v reportu zmiň.
- Element vytvořený pravidlem, který vypadá prázdný, může být jen ještě neaplikované pravidlo —
  než ho označíš za "chybí", ověř aktuálnost dat.
- Nikdy nevynucuj přepočet — Mergado ho dělá automaticky.
- Ověřené chování MCP a dat včetně čísel a data ověření: [`references/gotchas.md`](references/gotchas.md).
