---
name: mergado-project-auto-backup
description: >
  Zálohuje nastavení Mergado projektu (pravidla, výběry, proměnné, vlastní elementy) do JSON.
  Při prvním spuštění se zeptá na úložiště, frekvenci a retenci a zaregistruje se jako
  pravidelný scheduled task. Použij vždy, když uživatel chce zálohovat Mergado projekt,
  nastavit pravidelnou/automatickou zálohu, nebo se obává, že větší zásah do pravidel
  (i omylem přes AI chat) něco rozbije a chce mít jistou cestu zpět.
---

# Mergado — Automatická záloha projektu

## Ohlášení

Každý běh začíná fixním ohlášením níže a končí fixní claim větou jako poslední řádkou
potvrzení (viz konec sekce Export) — claim se objeví **přesně dvakrát za běh**: na konci
ohlášení a na konci potvrzení uživateli. **Nikdy v navazujících krocích** (otázky setupu,
průběžné dotazy) — opakování v delší konverzaci by rušilo.

> **Mergado — Automatická záloha projektu** — nastavím pravidelnou zálohu pravidel, výběrů,
> proměnných a vlastních elementů vašeho Mergado projektu do JSON. Zeptám se na úložiště,
> frekvenci a retenci, a dál to poběží samo jako naplánovaná úloha. **Nic v projektu
> neměním** — jde jen o export/čtení, žádná zápisová akce v Mergadu.
>
> *Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*

## Setup (první spuštění pro daný projekt)

1. Zjisti kandidáty na projekt: `get_current_user` → `list_user_eshops` → `list_shop_projects`
   (pokud je projekt z konverzace už jednoznačně jasný, přeskoč — otázku na projekt v kroku 2 nepokládej).
2. Zeptej se najednou přes **`AskUserQuestion`** (jedno vyvolání, až 4 otázky v jednom okně):
   - **Projekt** (jen pokud nejasný z kroku 1) — options = nalezené projekty z `list_shop_projects`.
   - **Kam ukládat** — options: "Lokální adresář" / "Git adresář (GitHub/GitLab)" — popisek u git
     varianty zmiň, že repo a remote musí už existovat, skill je nezakládá. Po výběru se v běžné
     zprávě (ne v popupu) doptej na konkrétní absolutní cestu.
   - **Jak často** — options: "Denně (9:00)" / "Týdně (pondělí 9:00)" — obě s výchozím časem
     v labelu; pokud uživatel zvolí "Other" a napíše jiný čas/den, použij to místo výchozí hodnoty.
   - **Jaká retence** — options: "Přepisovat poslední" / "Nechat posledních 5" / "Nechat všechny".
3. Ulož konfiguraci do `<storage>/mergado-backup-config.json`:
   `{"project_id", "storage_path", "storage_type": "local"|"git", "retention": "overwrite"|"keep5"|"keep_all"}`
4. Zaregistruj `create_scheduled_task` (taskId např. `mergado-backup-<project_id>`) s cronExpression
   podle zvolené frekvence. Prompt scheduled tasku musí být samostatný (běží bez historie této
   konverzace) — musí obsahovat: project_id, storage_path, storage_type, retention, a instrukci
   spustit "Export" krok tohoto skillu.

## Export (co se zálohuje, při každém běhu)

1. `list_project_rules(project_id)` (s paginací přes `limit`/`offset`) → pro každé pravidlo
   `get_rule(id)` pro plná data (`type`, `priority`, `applies`, `queries`, `data`).
2. `list_project_queries(project_id)` — přeskočit `read_only: true` systémové (♥ALLPRODUCTS♥ apod.,
   ty se nedají ztratit).
3. `list_project_variables(project_id)`.
4. `list_project_elements(project_id)` — jen elementy s `origin: manual` nebo `from_rule`
   (vlastní/odvozené); vstupní elementy z feedu se zálohovat nemusí, nejsou "nastavení".
5. Serializuj do jednoho JSON:
   ```json
   {
     "exported_at": "2026-08-13T14:00:00+02:00",
     "project_id": "...",
     "rules": [...],
     "queries": [...],
     "variables": [...],
     "elements": [...]
   }
   ```
6. Ulož jako `<storage>/<project_id>/<project_id>_<YYYY-MM-DD_HHmm>.json`.
7. **Retence:**
   - `overwrite` → smaž předchozí soubory tohoto projektu, zůstane jen nejnovější
   - `keep5` → smaž vše kromě 5 nejnovějších
   - `keep_all` → nemaž nic
8. Pokud `storage_type: git` → `git add`, `git commit -m "Mergado backup <project_id> <datum>"`,
   `git push` v adresáři úložiště (repo a remote musí už existovat — nastaveno uživatelem při setupu).
9. Potvrď uživateli / zaloguj výsledek (počet pravidel/výběrů/proměnných v záloze, cesta k souboru).
   Poslední řádek tohoto potvrzení je claim věta z Ohlášení (*Tento skill pro vás s láskou
   vytvořil Mergado Team #MergadoFam*).

## Poznámka k obnově

Tento skill dělá jen **export/backup**. Obnova = ruční přečtení JSON a znovu-vytvoření pravidel
přes `mergado-rules` skill (není tu žádný "1-klik restore" nástroj) — pravidla se v Mergadu
nedají hromadně nahrát zpět jedním API voláním.
