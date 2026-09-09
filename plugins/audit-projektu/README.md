# Skill: audit-projektu

Read-only audit feedového projektu napříč Mergadem a jeho rozšířeními (Pricing Fox, Bidding Fox, Feed Image Editor). Hledá logické nesmysly v datech, rozpory mezi názvem a obsahem výběrů a pravidel, duplicitní a mrtvá pravidla a rozpory mezi kanály.

**Verze 1.0.1**, vydáno 2026-08-21. Katalog obsahuje 145 kontrol v osmi oblastech.

Oproti 1.0 jen jedna oprava: v `description` skillu byly ostré závorky, kvůli kterým Claude Desktop odmítal balíček nahrát s hláškou „SKILL.md description cannot contain XML tags". Chování auditu se nemění.

## Instalace

```text
/plugin marketplace add mergado/mergado-skills
/plugin install audit-projektu@mergado-skills
```

Pak `/audit-projektu <eshop nebo projekt>`.

## Co je potřeba

Povinně napojené Mergado MCP. Rozšíření (Pricing Fox, Bidding Fox, Feed Image Editor) jsou volitelná: co není k dispozici nebo není na projektu používané, se přeskočí a zapíše do reportu jako nezkontrolované. Audit tedy dojede i s jediným napojeným serverem.

## Použití

```
/audit-projektu Muj eshop
/audit-projektu 123456 --quick              # fixní krátký seznam kontrol pro live ukázku
/audit-projektu 123456 --only mergado,pf    # jen vybrané oblasti
/audit-projektu 123456 --values output      # posuzuj jen to, co odchází na platformu
/audit-projektu 123456 --values input       # posuzuj jen zdrojová data od dodavatele
/audit-projektu 123456 --parallel           # rozdělí kategorie mezi subagenty
```

Default u `--values` je `both`: audit posuzuje vstup, výstup i **rozdíl mezi nimi**. Ten rozdíl bývá nejcennější, protože ukazuje, co s daty udělala pravidla (například název, do kterého dvě duplicitní pravidla vloží výrobce dvakrát).

## Výstup

Běh začíná **ohlášením** s výčtem toho, co je v session reálně připojeno, a tabulkou pokrytí. Končí markdown reportem `audit-<eshop>-<projekt>-<datum>.md` a souhrnem v chatu.

Report má pevnou strukturu, aby se dva audity daly srovnat:

- **Verdikt** v jednom řádku: kolik nálezů, jakých závažností, z kolika provedených kontrol a z kolika relevantních.
- **Nálezy** se závažností `Z1` až `Z3`, kódem kontroly z katalogu a **kategorií, čí je to práce**: `[DATA FEEDU]`, `[NASTAVENÍ MERGADA]`, `[ROZŠÍŘENÍ]`, `[OMEZENÍ PLATFORMY]`, `[MIMO FEED]`.
- **Vzorec** u nálezů nad pět zasažených objektů, tedy dotčený výběr nebo MQL podmínka místo výčtu produktů.
- **Tabulka pokrytí** s ikonami a vždy všemi osmi oblastmi, včetně těch, které se nekontrolovaly.
- **Sekce s tipy** označenými ℹ️, tedy doporučení nástrojů a otevřené otázky, které se nepočítají jako nálezy.

Report se dá použít jako základ pro srovnání při dalším auditu (kontrola X7).

## Struktura

```
SKILL.md                                  zásady, ohlášení, fáze, značení, vzorkování, chování při chybách
references/detekce-rozsireni.md           jak se zjišťuje, co je k dispozici
references/kontroly-mergado-data.md       ceny, identifikátory, názvy vs. kategorie, sezónnost, compliance
references/kontroly-mergado-konfigurace.md výběry a pravidla: názvy vs. obsah, duplicity, pořadí, mrtvá pravidla
references/kontroly-provoz.md             importy, exporty, logy, tarif, osiřelé objekty
references/kontroly-pricing-fox.md
references/kontroly-bidding-fox.md
references/kontroly-fie.md
references/kontroly-cross-app.md          rozpory mezi kanály a nástroji
references/kontroly-ai-sanity.md          volná AI pasáž a sebekontrola auditu
references/report-template.md             formát reportu a formát nálezu
```

## Známá omezení

- **MQL ignoruje diakritiku i velikost písmen**, a to u `CONTAINS` i u regulárního výrazu `~`. Dotaz na „Kč" vrátí i slovo „produkčního". Textové kontroly proto audit ověřuje na vráceném vzorku a tam, kde spolehlivá formulace není, označí kontrolu za nezkontrolovanou.
- **Přes MCP nejde:** spustit nový audit dat (`create_feedaudit`), přečíst stats audity ani vypsat nainstalované aplikace projektu. Mergado také nemá `update_rule`, takže doporučení mluví o nahrazení pravidla, ne o jeho úpravě.
- **Katalogy Bidding Foxu a Feed Image Editoru** jsou postavené na dokumentaci a čtecích nástrojích, ale zatím proběhly na menším počtu reálných projektů než katalogy Mergada. Nálezy z nich si ověřuj o něco pozorněji.

## Co skill zásadně nedělá

Nic nemění. Žádné vytváření, úpravy ani mazání pravidel, výběrů, šablon, importů a nastavení. Výstupem je nález a doporučení, ne provedená oprava. Díky tomu se dá pustit i na cizí projekt bez rizika.

Report proto končí nabídkou pokračování, která taky nic nemění: rozpracovat nález, připravit postup opravy, nebo vypsat objekty, kterých se oprava dotkne. Vlastní opravu předává dál, obsahovou optimalizaci Heurekového feedu skillu `mergado-heureka-optimization`, technické chyby feedu Shoptetu skillu `shoptet-feed-doctor`.

---

*Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*
