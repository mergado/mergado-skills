# Glossary — verified Mergado terminology (EN)

Use **only** these English terms. They are taken from the official English Knowledge Base (`help.mergado.com/en/`) and the product UI. Do not invent English names.

## Core concepts

| Concept | Official EN term | Note |
|---|---|---|
| Projekt | **Project** | one output setup for one online store |
| Vstupní feed / vstupní data | **Input feed** (input data) | original data downloaded from the store; not modified |
| Výstupní feed / výstup | **Output feed** (modified data) | final feed after rules, per platform |
| Produkt(y) | **Product(s)** | |
| Element(y) | **Element(s)** | attribute in the feed (e.g. `PRICE_VAT`, `g:title`) |
| Proměnná | **Variable** | reusable extracted value |
| Výběr produktů | **Product query** | a saved filter of products (NOT "product selection") |
| — dočasný / uložený | temporary query / **saved query** | |
| Pravidlo | **Rule** | transformation between input and output |
| Jednoduché vyhledávání | **Simple interface** | click-based search |
| MQL dotaz | **Custom MQL query** / **MQL** | Mergado Query Language (not SQL) |
| Přegenerování a aktualizace dat | **Data regeneration and updating** | automatic in the background |
| Pairing | **Pairing** | |
| Custom formát | **Custom Format** | user-defined output format |
| Napojení dat | **Data Connection** | connecting input/output feeds |
| Srovnávače / výstupní kanály | **Advertising Channels and Listings** | |

## Product tracing (from the UI)

| Concept | Official EN term |
|---|---|
| Sledované produkty | **Traced items / Traced products** |
| Sledovat změny (checkbox) | **Track changes to this product** |
| Sledování (záložka) | **Product tracing** |
| Zvýraznit rozdíly | **Highlight differences** |
| Spustit aplikaci pravidel (odkaz) | **Start rule apply** |

The UI menu **"Run processes manually"** offers **Regenerate changed**, **Apply rules**, and **Apply to traced items only**. These are for humans; the agent must not trigger recalculation via the MCP (see SKILL.md guardrails).

## Editing vs. conversion

- **Editing** — same platform in and out (e.g. `google.cz → google.cz`): you only modify the feed.
- **Format conversion** — different platform in and out (e.g. `shopify → kaufland`): a converter builds the target format.

## Knowledge Base

Primary source: **English** pages at `help.mergado.com/en/`. Sections: About Mergado, Working with Data, Rules, Automation, Feed Formats and Advanced Data Scenarios, Advertising Channels and Listings, Product Data Audit, Account Management and Billing, Integrations and Automation.
