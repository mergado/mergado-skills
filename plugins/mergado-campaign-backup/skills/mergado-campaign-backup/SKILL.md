---
name: mergado-campaign-backup
description: >
  Zálohuje nastavení speciální kampaně (Black Friday, Cyber Monday, Vánoce...) v Mergado
  projektu — konkrétní pravidla vytvořená pro danou kampaň, s poznámkami co fungovalo a co
  příště jinak. Použij vždy, když uživatel chce uložit/archivovat kampaňová pravidla po
  skončení akce, nebo znovu nahrát/najít loňské nastavení kampaně před další sezónou.
  Spouští se ručně, ne na časovač — nezaměňovat s mergado-project-auto-backup.
---

# Mergado — Záloha nastavení speciální kampaně

## Ohlášení

Každý běh začíná fixním ohlášením níže a končí fixní claim větou jako poslední řádkou
potvrzení (viz konec sekce Workflow) — claim se objeví **přesně dvakrát za běh**: na konci
ohlášení a na konci potvrzení uživateli. **Nikdy v navazujících krocích.**

> **Mergado — Záloha kampaňových nastavení** — archivuji pravidla vytvořená pro konkrétní
> sezónní kampaň (Black Friday, Vánoce...) spolu s poznámkami, co fungovalo a co příště
> jinak. Ukládám odděleně od automatické zálohy projektu. **Nic v projektu neměním** — jde
> jen o export/čtení, žádná zápisová akce v Mergadu.
>
> *Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*

## Kdy použít

Ad-hoc, typicky před spuštěním kampaně (uložit "výchozí stav") nebo po jejím skončení
(uložit finální nastavení + poznatky). Neřeší pravidelnou/celoprojektovou zálohu —
na to slouží `mergado-project-auto-backup`, a úložiště musí být oddělené.

## Workflow

1. **Zjisti kontext kampaně** — zeptej se na název (např. "Black Friday 2026") a projekt,
   pokud není z konverzace jasný.
2. **Najdi relevantní pravidla** — zeptej se uživatele, jak pravidla kampaně poznat
   (typicky prefix/název, např. "BF2026 - ..."), nebo ať vypíše konkrétní rule ID.
   Načti je přes `list_project_rules` + `get_rule` pro plná data, a jejich `queries`
   (`get_query`) a případné proměnné.
3. **Zeptej se na poznámky** — co fungovalo, co příště udělat jinak (volný text, uloží se
   do zálohy jako `notes`).
4. **Zeptej se, zda přiložit něco navíc** — např. export čísel/výsledků, screenshot
   nastavení. Pokud uživatel poskytne soubor/cestu, přilož ho do stejné složky zálohy.
5. **Zeptej se na úložiště** — výslovně **jiné/oddělené** od automatické zálohy
   (např. `<root>/campaigns/<projekt>/<kampan-slug>/`, ne stejná složka jako auto-backup).
6. Ulož jako JSON:
   ```json
   {
     "campaign": "Black Friday 2026",
     "saved_at": "2026-11-28T10:00:00+01:00",
     "project_id": "...",
     "rules": [...],
     "queries": [...],
     "variables": [...],
     "notes": {
       "what_worked": "...",
       "what_to_change_next_time": "..."
     },
     "attachments": ["results-export.csv"]
   }
   ```
   Soubor: `<kampan-slug>_<rok>.json` (žádná retence/rotace — kampaně se neopakují často,
   nechávat vše).
7. Pokud v dané složce kampaně (`<kampan-slug>/`) už existuje záloha z minulého roku,
   upozorni na to a nabídni ji nejdřív ukázat (ať uživatel vidí loňské poznámky, než přepíše).
8. Potvrď uživateli, co bylo uloženo a kam. Poslední řádek tohoto potvrzení je claim věta
   z Ohlášení (*Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*).

## Poznámka k obnově

Stejně jako u `mergado-project-auto-backup` — jde jen o export/archivaci. Znovu-vytvoření
pravidel z JSON je manuální přes `mergado-rules` skill, žádný bulk-restore neexistuje.
