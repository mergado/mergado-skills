# Mergado Skills

Shared [Claude Code](https://code.claude.com) skills for working with **Mergado Editor** and product feeds. This repository serves as both a **Claude plugin marketplace** and a **documentation source for [Context7](https://context7.com)**.

## Plugins

| Plugin | Description |
|---|---|
| **mergado-asistent** v2.1.0 | Assistant for Mergado Editor users — translates real business problems (Google Shopping errors, missing colours, hidden products) into actions via the Mergado MCP. Familiarizes itself with the project first, advises using online-store owner terminology, and only executes changes after user confirmation. |
| **audit-projektu** v1.0.1 | Read-only logical and operational audit of a feed project across Mergado and its extensions (Pricing Fox, Bidding Fox, Feed Image Editor). A catalogue of 145 checks looking for nonsense in the data, contradictions between the name of a query or rule and its content, duplicate and dead rules, wrong rule order and cross-app conflicts. Czech. |
| **ai-visibility-audit** v1.0.0 | Audits an online store's readiness to be discovered, cited and recommended by AI chat assistants and shopping agents (ChatGPT, Claude, Gemini, Perplexity, AI Overviews). Combines a live probe of the public website with internal data from every connected source. |
| **shoptet-feed-doctor** v1.0.0 | Validates, diagnoses and fixes Shoptet product feeds (Kompletní / Dodavatelský XML) — local RNG validation, decoding the misleading Shoptet validator messages, correct element placement for variants and merging standalone items into variants. |
| **mergado-google-ads-optimization** v1.0.0 | Content and marketing optimization of a Google Shopping feed. Diagnoses nine pillars, reports findings with their impact and, after approval, creates the corresponding Mergado rules. |
| **mergado-heureka-optimization** v1.0.0 | The same for a Heureka feed — product pairing, CPC and bidding segmentation, delivery, conversion extra elements, `ITEM_TYPE`. |
| **mergado-meta-optimization** v1.0.0 | The same for a Meta (Facebook, Instagram) catalog — `custom_label` and `custom_number` segmentation, categories, stock availability, pixel matching. |
| **mergado-project-auto-backup** v1.0.0 | Backs up a project's rules, queries, variables and custom elements to JSON and registers itself as a recurring scheduled task with configurable storage, frequency and retention. Czech. |
| **mergado-campaign-backup** v1.0.0 | Backs up the rules of a seasonal campaign (Black Friday, Christmas) together with notes on what worked, so last year's setup can be found before the next season. Runs on demand. Czech. |

## Installation in Claude Code

```text
/plugin marketplace add mergado/mergado-skills
/plugin install mergado-asistent@mergado-skills
```

Install any other plugin the same way — for example `/plugin install shoptet-feed-doctor@mergado-skills`. Once installed, a skill activates on its own whenever the conversation matches what it covers; no slash command is needed, though `audit-projektu` also accepts one (`/audit-projektu <shop or project id>`).

> Every plugin here requires the **Mergado MCP** server (read and write access to user projects). Make sure you have Mergado MCP configured in Claude for full functionality.

### Extra requirements

Most plugins need nothing beyond the Mergado MCP. Three exceptions:

| Plugin | Needs | Without it |
|---|---|---|
| `ai-visibility-audit` | `bash` and `curl` for `scripts/audit.sh` | The live website probe cannot run — notably on Windows without WSL or Git Bash. The rest of the audit still works from MCP data. |
| `shoptet-feed-doctor` | Python with `lxml` (`pip install lxml`), or `xmllint` as a fallback | Local RNG validation cannot run; the diagnostic parts of the skill still work. |
| `mergado-project-auto-backup` | A scheduled-tasks MCP server | The backup runs once but cannot register itself as recurring. |

## Usage via Context7

This repository is registered on Context7 as a documentation source. To add or refresh:

1. Open <https://context7.com/add-library?tab=github>
2. Source = **GitHub**, paste URL `https://github.com/mergado/mergado-skills`
3. **Submit**

Context7 indexes markdown from the folders listed in [`context7.json`](./context7.json) — one entry per skill.

## Repository Structure

```text
mergado-skills/
├── .claude-plugin/
│   └── marketplace.json          # marketplace manifest (list of plugins)
├── plugins/
│   └── <plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json        # plugin manifest
│       ├── README.md              # optional, plugin-level docs
│       └── skills/
│           └── <skill-name>/
│               ├── SKILL.md       # skill entry point
│               ├── references/    # detailed playbooks and reference materials
│               ├── scripts/       # optional executable helpers
│               └── examples/      # optional sample data
├── context7.json                  # Context7 indexing configuration
├── README.md
└── LICENSE
```

One plugin holds one skill and both share the same name. Supporting material lives in `references/` (plural) — keep that name so the layout stays predictable across plugins.

## Adding a New Skill

1. Create `plugins/<name>/.claude-plugin/plugin.json` and `plugins/<name>/skills/<name>/SKILL.md`.
2. Add an entry to the `plugins` array in `.claude-plugin/marketplace.json` and bump its `version`.
3. Add the skill folder to `folders` in `context7.json`.
4. Add a row to the table above, and to **Extra requirements** if the skill needs more than the Mergado MCP.

Keep `SKILL.md` itself lean — it loads in full every time the skill triggers. Detail belongs in `references/`.

## License

[MIT](./LICENSE) © Mergado s.r.o.
