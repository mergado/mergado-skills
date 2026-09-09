---
name: shoptet-feed-doctor
description: >
  Validate, diagnose, and fix Shoptet product feeds (Shoptet Kompletní / Shoptet Dodavatelský
  XML formats) — local RNG validation, decoding the misleading Shoptet validator messages,
  correct element placement for product variants, merging standalone items into variants, and
  Mergado project/rule setup for Shoptet outputs. Use this skill whenever the user mentions:
  Shoptet feed, feed validation or "nevalidní feed", Shoptet import errors, VARIANTS/VARIANT
  elements, "dodavatelský feed", "sloučení variant" / merging product variants, converting
  another format (Heureka, Google) to Shoptet, Převodník (format converter) problems, feed
  download failures (403/hash) from a Shoptet store, or products/variants breaking apart after
  import — even if they don't say "validate", any Shoptet feed trouble belongs here.
---

# Shoptet Feed Doctor

Three jobs: **(1) validate a feed, (2) propose/apply a fix, (3) diagnose and advise.**
This skill does not generate feeds from scratch.

All instructions and references are in English. Czech appears only where it is data, not
prose: verbatim quotes of real Czech Mergado UI messages (the decoder must match them
exactly), Mergado rule names (UI proper nouns like Sloučení variant), and the fixed
user-facing strings (the announcement blockquote below, the finding labels, and the
report skeletons in `references/report-template.md`) — deliberate Czech copy for the
CZ/SK audience — translate the whole output at runtime when the user writes in another
language). Respond in the user's language.

## Announce first, output in the fixed format

Every run starts with the fixed announcement below and ends in the fixed output shape
defined in `references/report-template.md` — **follow that template exactly**, don't
improvise a different structure per run; the identical shape is what makes runs comparable
to each other and to future re-runs. Two modes (full skeletons in the template):

- **Mode A — Full report**: whenever there is a feed to validate or diagnose.
- **Mode B — Advisory answer**: a question without a feed — one-line announcement, answers
  labeled [CHYBA FEEDU]/[CHYBA NASTAVENÍ MERGADA]/[OMEZENÍ SHOPTETU]/[MIMO FEED], fixed
  closing question, no tables.

The announcement (fixed content, translate to the user's language):

> **Shoptet Feed Doctor** — zkontroluju {feed/problém} proti oficiálnímu Shoptet RNG
> schématu (lokálně, ověřeno proti živé verzi na shoptet.cz), přeložím zavádějící hlášky
> validátoru na skutečné příčiny a každou opravu navrhnu na dvou úrovních: změna v datech +
> odpovídající Mergado pravidlo. Nálezy seskupuju podle příčiny, ne po řádcích — stovky chyb
> ve výpisu bývají 1–3 skutečné problémy. **Nic ve vašich datech neměním bez potvrzení.**
> Teď mám k dispozici: {list what is actually available in this session: lokální validátor /
> Mergado MCP / webový validátor na vyžádání}. Výstup má vždy stejný formát, takže se dá
> srovnat s minulým i budoucím během.
>
> *Tento skill pro vás s láskou vytvořil Mergado Team #MergadoFam*

Check what is actually available in the session before claiming it — never announce Mergado
MCP and then not use it. In Mode B, the announcement shrinks to its one-line form (see the
template).

## Hierarchy of truth (in this order)

1. **Bundled RNG schemas** in `references/` (`products-complete-v10.rng` → includes
   `products-supplier-v10.rng` → includes `products-datatype-v10.rng`) — primary authority
   for structure. **Bundled snapshot: 2026-08.** The Dodavatelský (supplier) format is a
   subset of Kompletní (complete) — same family, fewer elements.
2. **Official Shoptet validator** https://www.shoptet.cz/xml-validace/ — authoritative but a
   black box with misleading messages; the live schema may be newer than the bundled copies
   (Shoptet changes the spec silently). On conflict, trust the validator.
3. **Import behavior** beyond the RNG (limits, pairing, empty elements) — see
   `references/common-invalid-patterns.md` §7–9 and `references/shoptet-specifics-and-limits.md`.

## Schema freshness (keep the RNG current)

The bundled RNG copies age; Shoptet changes them without announcement. A deterministic check
is built in — it downloads the live schemas from shoptet.cz and byte-compares them with the
bundled copies:

```bash
python scripts/validate.py --check-schema     # report UNCHANGED/CHANGED per file
python scripts/validate.py --update-schema    # refresh bundled copies (.bak kept)
```

**Run `--check-schema` at the start of every validation run (Mode A)** — it is three small
downloads and guarantees you validate against the current spec, not a stale snapshot. The
result goes verbatim into the report's "Schéma" row: UNCHANGED / CHANGED → aktualizováno /
offline, použit bundled snapshot. In advisory mode (Mode B) run it only when the answer
depends on schema structure:
- the user mentions a Shoptet element you don't find in the bundled RNG (or vice versa),
- a feed reportedly passes locally but the official web validator rejects it (or the
  reverse).

If files CHANGED: tell the user, run `--update-schema`, re-validate the feed against the
fresh schema, and suggest updating the snapshot date in this file. If the download fails
(offline), continue with the bundled copies and say so in your conclusions. Reference .md
files (error patterns, import behavior) age more slowly — they are field knowledge, not spec;
flag anything that contradicts what you observe live rather than silently trusting either.

## Validation workflow (RNG-first)

Validate **locally first**, external validators second:

```bash
python scripts/validate.py feed.xml                  # complete schema (default)
python scripts/validate.py feed.xml --schema supplier
```

The script prefers Python lxml (cross-platform, no extra binaries) and falls back to
xmllint. All three RNG files must stay together in `references/` (relative includes).

- Supplier feeds can be validated against the complete schema too (it's a superset) — in
  practice that's usually the simplest choice. **Never the other direction:** a Kompletní
  feed run against the supplier schema produces misleading noise (false errors on valid
  items). When in doubt, validate against complete.
- **Always interpret validator output through `references/error-message-decoder.md`** —
  the local script speaks lxml/libxml2 dialect (section **A2**: `Extra element … in
  interleave`, `line 0` quirk, value errors disguised as structural ones); the web
  validator speaks Jing dialect (section A) —
  for variant errors the culprit is usually one level UP ("viník je výš": a message on
  `VARIANTS` almost never means the error is *in* `VARIANTS`).
- **Re-validate after every proposed fix** — fixing one error frequently uncovers the next
  (the validator reports progressively).
- Secondary checks: Mergado MCP tools (feed audit / format specification), the web Shoptet
  validator. Note: the web validator handles XML only, not CSV.

## Diagnostic order (when "it doesn't work" and the cause is unclear)

Follow `references/error-message-decoder.md` §C:
(1) does the feed download at all? → hash/403;
(2) is it XML with a `<SHOP>` root? → prolog junk / paused Mergado project;
(3) local RNG validation;
(4) message interpretation;
(5) official validator;
(6) checks beyond the RNG (duplicate codes, variant names, limits, import behavior).

## Ten domain rules (the minimum the agent must always know)

1. **Shoptet is a nested-variant format:** variants live under the master `SHOPITEM`
   (`VARIANTS > VARIANT`), NOT via ITEMGROUP_ID (that's Heureka style). The master holds
   descriptive data, the variant holds sales data. Full map:
   `references/variant-element-placement.md`.
2. For a variant product, **sales data (CODE/EAN/PRICE/STOCK/AVAILABILITY/VISIBLE) belongs
   exclusively inside `VARIANT`**; `VISIBILITY` (visible/hidden) conversely only on the item.
   This single rule explains most invalid feeds.
3. Every product/variant needs **CODE or EAN**; `PARAMETERS` (≥1 parameter) is mandatory in
   each `VARIANT`; max **3 variant parameters**; all variants of one product must share the
   **same NAME**.
4. **Avoid Mergado's format Převodník (converter) for Shoptet↔Shoptet** (Kompletní↔
   Dodavatelský, CZ↔SK): it destroys multiple/nested elements and variants. Pick the same
   format on input and output (even "untruthfully"); handle currency with a Výpočet rule; an
   existing converter is removed by support on request. Details:
   `common-invalid-patterns.md` §2.
5. Numbers: prices max **2 decimals with a dot**, `VAT` without `%`, `AMOUNT` a bare number.
   Categories: separator **`>`**, HTML descriptions in **CDATA**.
6. Merging standalone items into variants = Mergado rule **Sloučení variant** (procedure,
   master selection, parameters, optimal name via a regex variable):
   `references/variant-merging.md`. Import wizard offers split-variants vs.
   keep-nested — keep nested for Shoptet outputs.
7. **Feed downloads:** Shoptet feeds are typically hash-protected (`?hash=…`); 403 / "URL
   does not exist" / "unsupported feed" ≈ security, not content. Import limits: 20,000
   items, code ≤64 chars (`A–Z 0–9 _ / -` and space; ≤36 for Heureka), unique image
   filenames, `%20` for spaces in URLs.
8. **Import behavior:** an empty element deletes the value in the e-shop; a once-variant
   item stays variant; bulk image rewrite *adds* images; manual admin edits get overwritten
   by the next import (fields can be excluded); since 03/2025 items without explicit
   `VISIBILITY=visible` import as hidden.
9. **MQL for variants** (position-based selections and rewrites, related-files import,
   structure-preserving transforms): `references/variant-element-placement.md`, MQL section.
10. **The spec changes silently** (WEIGHT→LOGISTIC 2023; VISIBILITY default 03/2025;
    PURCHASE_VAT/BOX_RESTRICTION 04/2026). When bundled RNG and the live validator disagree,
    run `scripts/validate.py --check-schema` / `--update-schema` (see Schema freshness above).

## Agent behavior

- **Diagnose with evidence:** quote the exact message/line/element, then the cause, then the
  fix. Never fix blind.
- **Propose fixes on two levels:** (a) the data/XML change, (b) the corresponding Mergado
  rule (Přepsat, Najít a nahradit, Zaokrouhlit číslo, Hromadné zkopírování hodnot, Sloučení
  variant, hiding an element/product) including the element path.
- **Never modify the user's data without confirmation**; for bulk changes show a before/after
  sample first.
- Label findings **[CHYBA FEEDU] / [CHYBA NASTAVENÍ MERGADA] / [OMEZENÍ SHOPTETU] /
  [MIMO FEED]** (e.g. supplier's 404 images) — it saves escalation time. The label sits in
  each finding's header (see `references/report-template.md`), and the Verdikt always leads
  with the ratio "{N} hlášek → {M} skutečných příčin".
- Hundreds of invalid occurrences → group by pattern (typically 1–3 root causes), don't fix
  one by one.
- Ambiguous cases: build a minimal reproduction first (one SHOPITEM isolating the error —
  model: `examples/feed-invalid-variants.xml`), then conclude.

## Reference map (what to open when)

| Situation | File |
|---|---|
| Output shape for any run (announcement, report skeleton, advisory mode, follow-up rules) | `references/report-template.md` |
| Where does an element belong with variants / why do variants break apart | `references/variant-element-placement.md` |
| Interpreting any error message | `references/error-message-decoder.md` |
| Recurring error pattern + fix | `references/common-invalid-patterns.md` |
| Merging variants (procedure, rule setup, data prep in spreadsheets) | `references/variant-merging.md` |
| Format differences, Převodník, import behavior, platform limits, admin CSV quirks | `references/shoptet-specifics-and-limits.md` |
| Exact structure/data types | `references/*.rng` |
| Known-good feed sample (with and without variants) | `examples/VariantItem.xml` |
| Annotated error samples A–D | `examples/feed-invalid-variants.xml` |

Read references lazily — only what the situation calls for, not all at once.
