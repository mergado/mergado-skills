# Mergado Skills

Sdílené [Claude](https://claude.com/claude-code) dovednosti (skills) pro práci s **Mergado Editorem** a produktovými feedy. Repo slouží zároveň jako **Claude plugin marketplace** a jako **zdroj dokumentace pro [Context7](https://context7.com)**.

## Obsah

| Plugin | Popis |
|---|---|
| **mergado-asistent** | Asistent pro uživatele Mergado Editoru — překládá jazyk problémů (chyby v Google Shopping, doplnění barev, nezobrazený produkt) do akcí přes Mergado MCP. Nejdřív se zorientuje v projektu, poradí v termínech majitele e-shopu a teprve po potvrzení provede změny. |

## Instalace do Claude Code

```text
/plugin marketplace add mergado/mergado-skills
/plugin install mergado-asistent@mergado-skills
```

Po instalaci se skill `mergado-asistent` aktivuje automaticky, kdykoli uživatel mluví o feedu, produktech, Google Shopping / Heureka / Zboží / Meta / Glami, GMC chybách, optimalizaci feedu nebo importu nového e-shopu.

> Skill využívá **Mergado MCP** server (čtení i zápis nad projekty uživatele). Pro plnou funkčnost je potřeba mít Mergado MCP nakonfigurovaný v Claude.

## Použití přes Context7

Repo je registrované na Context7 jako zdroj dokumentace. Přidání / refresh:

1. Otevři <https://context7.com/add-library?tab=github>
2. Source = **GitHub**, vlož URL `https://github.com/mergado/mergado-skills`
3. **Submit**

Context7 indexuje markdown ze složky definované v [`context7.json`](./context7.json) (`plugins/mergado-asistent/skills/mergado-asistent`).

## Struktura repa

```text
mergado-skills/
├── .claude-plugin/
│   └── marketplace.json          # marketplace manifest (seznam pluginů)
├── plugins/
│   └── mergado-asistent/
│       ├── .claude-plugin/
│       │   └── plugin.json        # manifest pluginu
│       └── skills/
│           └── mergado-asistent/
│               ├── SKILL.md       # vstupní bod skillu
│               └── references/    # detailní playbooky a referenční materiály
├── context7.json                  # konfigurace indexace pro Context7
├── README.md
└── LICENSE
```

## Přidání dalšího skillu

1. Vytvoř `plugins/<nazev>/.claude-plugin/plugin.json` a `plugins/<nazev>/skills/<nazev>/SKILL.md`.
2. Přidej položku do pole `plugins` v `.claude-plugin/marketplace.json`.
3. (Volitelně) rozšiř `folders` v `context7.json`.

## Licence

[MIT](./LICENSE) © Mergado s.r.o.
