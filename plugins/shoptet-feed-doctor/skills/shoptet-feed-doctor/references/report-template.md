# Output template — fixed shape, every run

This structure is used every time, so runs are comparable to each other and to future
re-runs. Two output modes; pick by whether there is a feed:

- **Mode A — Full report**: there is a feed to validate or diagnose. Full skeleton below.
- **Mode B — Advisory answer**: a question without a feed. One-line announcement, labeled
  answers, fixed closing question. No tables, no report skeleton.

A third shape, the **follow-up** (Mode C), is what happens after the closing question —
rules at the end.

The fixed Czech strings below are the canonical wording; translate the whole output to the
user's language if they write in another one, keeping the structure identical.

## Status icons — five, defined ABOVE the findings, and the semantics matter

- ✅ **v pořádku**
- ⚠️ **projde validací, ale způsobí problém při importu** — the most valuable category this
  skill has ("validní ≠ importovatelný"): missing VISIBILITY, empty elements, duplicate
  codes, code charset/length. Never downgrade these to a footnote.
- ❌ **nevalidní / blokuje import**
- ➖ **netýká se tohoto feedu** (e.g. variant checks on a feed without variants)
- ℹ️ **jen informace, nehodnotíme**

## Hard rules for both modes

- **Verdikt leads with the ratio `{N} hlášek validátoru → {M} skutečných příčin`** — that
  compression is this skill's main value; it belongs in the first sentence.
- Every finding carries a **count** ("96 produktů", "34 hlášek") — never "většinou" or
  "hodně".
- Every finding header carries one of the four labels:
  **[CHYBA FEEDU] / [CHYBA NASTAVENÍ MERGADA] / [OMEZENÍ SHOPTETU] / [MIMO FEED]**.
- Quote the exact validator message in backticks, with a line number and one concrete
  product (CODE or NAME) as evidence.
- Fixes always on two levels: **Oprava v datech** + **Oprava v Mergadu** (rule name +
  element path + selection). If Mergado MCP is not connected, say so and give the data-level
  fix only, noting what the Mergado level would be.
- The beyond-RNG table has **8 fixed rows, always all present** — a row that does not apply
  is ➖ with a one-line reason, never dropped.
- Recommendations: **max 5, one sentence each**, ranked by impact. More than 5 worth doing →
  short secondary list, don't bury the top 5.
- "Co jsme NEmohli ověřit" is mandatory — import-log-only behavior, web validator if not
  run, live schema if offline, Mergado settings if MCP not connected.
- Detailed step-by-step fixes and any Mergado writes happen **only in Mode C**, never
  unprompted.
- **Credits claim**, fixed wording: *Tento skill pro vás s láskou vytvořil Mergado Team
  #MergadoFam* — appears exactly twice per run: as the announcement's last line and as the
  output's final footer line (italics, after the closing question). **Never in Mode C
  follow-ups** — repeating it in an ongoing conversation gets annoying. If the user writes
  in another language, translate the sentence but keep "Mergado Team" and "#MergadoFam"
  verbatim.

---

## Mode A — Full report skeleton

Open with the announcement (fixed wording in SKILL.md), then:

```
# Shoptet Feed Doctor — {soubor / URL / projekt}

## Vstup a metoda

| | |
|---|---|
| Feed | {soubor/URL, velikost, počet SHOPITEM, z toho variantních} |
| Formát | Shoptet Kompletní / Shoptet Dodavatelský |
| Schéma | {schema file} — snapshot {date}; `--check-schema`: UNCHANGED / CHANGED → aktualizováno na live verzi / offline, použit bundled snapshot |
| Validace | lokální RNG (lxml) / + webový validátor / jen webový |
| Datum | {date} |

**Legenda:** ✅ v pořádku · ⚠️ projde validací, ale způsobí problém při importu ·
❌ nevalidní / blokuje import · ➖ netýká se tohoto feedu · ℹ️ jen informace

## Verdikt

❌ **NEVALIDNÍ** — {N} hlášek validátoru → **{M} skutečných příčin** u {K} produktů.
{one sentence on the healthy remainder}
(nebo: ✅ **VALIDNÍ proti RNG** — ale **validní ≠ importovatelný**: {M} nálezy níže.)

## Nálezy ({M}) — seskupené podle příčiny

### Nález 1 — {jednověté pojmenování} — [CHYBA FEEDU] ❌
- **Rozsah:** {X produktů / Y hlášek — always numbers}
- **Hláška:** `{verbatim message}` (řádek {n}, produkt {CODE/NAME})
  {for lxml "Extra element X in interleave" traps add: "pozor, past: …" per dekodér A2}
- **Skutečná příčina:** {per dekodér — including the "viník je výš" translation}
- **Oprava v datech:** {what exactly to move/change, with a before/after sample on 1 product}
- **Oprava v Mergadu:** {rule + element path + selection} / n/a — {reason}

## Kontroly nad rámec RNG (vždy všechny)

| # | Kontrola | Stav | Nález |
|---|---|---|---|
| 1 | CODE/EAN u každého produktu i varianty | ✅/❌ | {counts} |
| 2 | Duplicitní CODE | ✅/❌ | {which, with line numbers} |
| 3 | Shodný NAME všech variant produktu | ✅/❌/➖ | ➖ = feed bez variant |
| 4 | Max 3 variantní parametry / PARAMETERS v každé VARIANT | ✅/❌/➖ | |
| 5 | Formát čísel (ceny 2 des. místa, VAT bez %, AMOUNT číslo) | ✅/⚠️/❌ | |
| 6 | Limity importu (20 000 položek, kód ≤64 znaků a povolené znaky, znaky v URL) | ✅/⚠️ | |
| 7 | VISIBILITY explicitně (od 03/2025 jinak import jako skryté) | ✅/⚠️ | |
| 8 | Prázdné elementy (import smaže hodnotu v e-shopu) | ✅/⚠️/ℹ️ | |

## Doporučený postup (max 5, jedna věta, seřazeno podle dopadu)
1. {concrete, named fix — blocking causes first}

## Co jsme NEmohli ověřit
{import behavior without the Shoptet import log; web validator if not run; live schema if
offline; Mergado rules/settings if MCP not connected — and what connecting would add}

---

Mám některou z oprav rozepsat do konkrétních kroků, nebo ji rovnou provést (u Mergado
pravidel až po vašem potvrzení)? Napište číslo nálezu, nebo „všechny".

*Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*
```

## Mode B — Advisory answer (no feed)

```
**Shoptet Feed Doctor** — odpovídám z ověřené znalostní báze skillu (snapshot {date}).

**{1) Question restated briefly} — [LABEL]**

{Direct answer: real cause first, then the concrete fix — where exactly in Shoptet admin /
which Mergado rule. Same evidence discipline as Mode A, no tables.}

---

Chcete k některému bodu konkrétní kroky? Napište číslo.

*Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*
```

## Mode C — Follow-up (after the closing question)

Only after the user names finding numbers (or "všechny"):

- Expand exactly the named findings into numbered, concrete steps — where in Mergado
  (rule type, element, selection, **priority relative to existing rules**) or where in the
  Shoptet admin.
- Each expanded finding is its own clearly separated block.
- Offer verification (`query_products` before/after sample) where Mergado MCP is connected.
- **Any write to Mergado (creating rules, elements, queries) happens only after the user's
  explicit confirmation in this step — never as part of the report.**
- If a fix is outside this skill's reach (Shoptet support, supplier's data), say which
  tool/party is needed rather than describing it vaguely.
- No credits claim here — it already ran in the announcement and the report footer.
