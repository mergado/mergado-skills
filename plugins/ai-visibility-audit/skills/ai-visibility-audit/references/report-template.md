# Report template — fixed shape, every audit

This exact structure is used for every store, every time. Rows are fixed and always all
present — a row that doesn't apply still shows up, marked `n/a` (or the neutral status, see
below) with a one-line reason, rather than being omitted. That's what makes two audits
comparable to each other.

**Audience calibration.** The readers run online stores and came to a workshop about
connecting AI tools to their product data — they know what a sitemap, robots.txt, EAN, or a
product feed is. Don't explain those. What they likely *haven't* seen are the newer
mechanisms: `llms.txt`, MCP servers, UCP manifests. Rules:

1. **Use the real technical term as the Check label**, always.
2. **The Finding column is a concrete, specific sentence, never a bare fragment.** If a store
   uses an older format instead of the recommended one, name both formats ("microdata" and
   "JSON-LD"), never just "an older format".
3. Only rows 10–12 (`llms.txt`, MCP, UCP) carry the fixed one-line explainer given below,
   worded the same way every time.

## Status icons — five, and the meaning matters

Define these **above** the findings table, not below it.

- ✅ **splňuje** — meets the baseline
- ⚠️ **částečně / stojí za zlepšení** — present but weaker approach, or inconsistent across
  the sample
- ❌ **chybí a reálně omezuje viditelnost** — a real, actionable gap
- ➖ **chybí, ale u běžného e-shopu to dnes nic neřeší** — an edge mechanism with narrow
  adoption. **Never mark these ❌** — a red X reads as "you have a problem," which would be
  misleading. Reserve ➖ for rows 11 and 12, and for row 10 only when the file is genuinely
  absent (exists-but-empty is a minor ⚠️).
- ℹ️ **jen informace, nehodnotíme** — platform/tech-stack row only

---

```
# AI Visibility Audit — {store domain}

> **AI Visibility Audit** — Zkontroloval jsem, jak je {store domain} připravený na to, aby ho
> AI systémy (Google AI Overviews/AI Mode, ChatGPT, Claude, Perplexity) uměly najít, správně
> popsat a doporučit. Report má vždy stejný formát, takže se dá srovnat s jinými e-shopy i s
> budoucím opakováním auditu.

## Zdroje dat pro tento běh

| Zdroj | Stav | Co dodává |
|---|---|---|
| Web (veřejná sonda) | ✅ vždy | co reálně vidí AI crawlery zvenčí |
| Mergado MCP | ✅ připojeno / ⬜ nepřipojeno | pravda o feedu napříč všemi projekty: kompletnost atributů, rozbitá pravidla, zastaralé synchronizace |
| Google Merchant Center | ✅ připojeno / ⬜ nepřipojeno | free listings opt-in, zamítnuté produkty, skóre kompletnosti, AI Performance Insights |
| Search Console | ✅ připojeno / ⬜ nepřipojeno | reálná indexace produktových URL, dotazy, pokrytí sitemap |

{One line total, only if something is missing: "Čím víc zdrojů je připojeno, tím víc řádků
reportu je z reálných dat místo odhadu zvenčí — chybějící zdroje se dají připojit a audit
spustit znovu."}

## Co jsme kontrolovali
- Stránky ({N} celkem): {plainly — "hlavní stránka, 2 kategorie (X, Y), 4 produkty napříč
  sortimentem"}
- Interní data: {which projects/samples were pulled from Mergado, or "žádná — MCP nepřipojeno"}
- Datum: {date}

Vzorek, ne celý katalog. Když se nálezy na vzorku shodují (stejný vzorec na všech stránkách),
je to silný signál — proto vzorek nikdy není jen 1 produkt.

**Legenda:** ✅ splňuje · ⚠️ částečně / stojí za zlepšení · ❌ chybí a reálně omezuje
viditelnost · ➖ chybí, ale u běžného e-shopu to dnes nic neřeší · ℹ️ jen informace

## Co jsme zjistili

| # | Kontrola | Stav | Nález |
|---|---|---|---|
| 1 | Platforma / technologie webu | ℹ️ | {e.g. "WordPress + WooCommerce"} |
| 2 | Server-side rendering | ✅/⚠️/❌ | {is name/price/description in raw HTML} |
| 3 | robots.txt — přístup AI robotů (GPTBot, ClaudeBot, PerplexityBot, Google-Extended...) | ✅/⚠️/❌ | {which bots are/aren't blocked, by name} |
| 4 | Sitemap.xml | ✅/⚠️/❌ | {exists, URL count, flat vs index} |
| 5 | Meta title & description | ✅/⚠️/❌ | {X of N sampled pages have both} |
| 6 | Structured data u produktů (Product/Offer schema) | ✅/⚠️/❌ | {microdata vs JSON-LD — name both} |
| 7 | Structured data u recenzí (AggregateRating/Review) | ✅/⚠️/❌ | {present, or absent across the whole sample} |
| 8 | Identifikátory produktu (GTIN/EAN/MPN) | ✅/⚠️/❌ | {standard code, or internal SKU only — cross-reference the feed finding when Mergado ran} |
| 9 | FAQ/Q&A structured data | ✅/⚠️/❌ | {FAQPage/Question schema present or missing} |
| 10 | llms.txt | ✅/⚠️/➖ | {finding}. **Fixní vysvětlení, jen když je relevantní:** dobrovolný soubor, který má webu pomoct "vysvětlit se" AI systémům — podle dosavadních zjištění ho ale žádný velký AI systém v produkci reálně nečte (Google to i veřejně potvrdil). Existuje-li a je prázdný → ⚠️ (mrtvý soubor); chybí-li úplně → ➖. |
| 11 | MCP server (strojové rozhraní pro AI agenty) | ✅/➖ | {finding}. **Fixní vysvětlení, jen když chybí:** ➖ dnes to běžně mají jen obchody na Shopify (Storefront MCP) — pro ostatní platformy to není standard, absence není nedostatek, jen stav trhu 2026. |
| 12 | UCP manifest (`/.well-known/ucp`) | ✅/➖ | {finding}. **Fixní vysvětlení, jen když chybí:** ➖ soubor, díky kterému by objednávkový AI agent (dnes hlavně na straně Google) zjistil, jak s obchodem obchodovat. Zatím jen pár největších platforem — okrajová, začínající věc. |
| 13 | Interní data feedu (Mergado) | ✅/⚠️/❌/n/a | {one-line summary of the internal section below, or "n/a — Mergado MCP nepřipojeno"} |

## Interní nálezy z Mergada {only when Step 3 ran — omit the whole section otherwise}

### Projekty e-shopu ({N} celkem)
| Projekt | Kanál | Produktů | Poslední sync | Stav |
|---|---|---|---|---|
| {name} | {output_format} | {exported_items} | {age — flag > 7 days, months = 🔴} | {OK / dirty / paused} |

### Nálezy z feedů (vzorek {N} produktů z {which projects})
- {numbered, each with a count: "GTIN prázdný u 10 z 10 vzorkovaných produktů (Google i
  Heureka) — problém je ve zdrojových datech, ne v pravidlech"}
- {masking rules found, with one concrete product as evidence}
- {description quality, with ONE truncated quoted example}
- {cross-channel inconsistencies}
- {AI-attribute readiness: which of g:product_highlight / g:product_detail /
  g:question_and_answer etc. exist in the structure but are unfilled}
- {performance elements found (e.g. Search Console data piped into the feed) and what they
  show}

## Doporučení — co udělat nejdřív (max. 5, jedna věta každé)
1. {Concrete, named fix — the strongest findings first, cross-source when possible}
2. ...
3. ...
4. ...
5. ...

(More worthwhile fixes than 5 → short secondary list below, don't bury the top 5.)

## Co jsme NEmohli zkontrolovat
{Explicitly: how many products of the whole catalog; which missing connection would unlock
which check — e.g. "bez Merchant Center nevíme, jestli jsou zapnuté bezplatné výpisy —
připojením a novým během auditu se tento řádek doplní". If the platform-requirements
reference was stale and could not be refreshed (no web search in session), add one line:
"referenční data platforem naposledy ověřena {date} — rychle se měnící fakta se od té doby
mohla změnit". If it WAS refreshed this run, instead note what changed, briefly.}

---

Chcete, abych některé z těchto doporučení rozepsal do konkrétních kroků — co přesně a kde
upravit? Napište číslo (nebo "všechny") a udělám to hned.

*Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*
```

---

## Style notes

- Real terms as labels, concrete sentences as findings. Every internal claim carries a count
  ("0 z 10"), never "většinou chybí".
- ➖ vs ❌ is not stylistic — a red X on an edge mechanism (MCP/UCP absence, llms.txt not
  existing) misleads the reader into seeing a problem they don't have.
- Cross-reference internal and external findings explicitly whenever they agree — that's the
  single most persuasive pattern in the report ("chybí na webu I ve feedu → opravit u zdroje").
- The recommendations list is titles only; the "how" is Step 8, on request.
- The sources table is also the nudge: missing connections are shown neutrally (⬜), with what
  they'd add — no guilt-tripping, one summary line max.
- **Credits claim** (fixed wording: *Tento skill pro vás s láskou vytvořil Mergado Team
  #MergadoFam*) appears exactly twice per run — last line of the Step 1 announcement and the
  report's final footer line. Never in Step 8 follow-ups. In another language, translate the
  sentence but keep "Mergado Team" and "#MergadoFam" verbatim.
