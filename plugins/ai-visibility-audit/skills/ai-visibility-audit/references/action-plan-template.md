# Action plan template — Step 8 only, on request

Used only after the user points at one, several, or all numbered recommendations from the
report and asks for concrete steps. Never produced automatically as part of the main audit.

For each recommendation the user picked, use this block:

```
### {N}. {Recommendation title, copied from the report}

**Why it matters:** {one sentence — which platform(s)/mechanism this affects, from
references/platform-requirements.md — not a generic "improves AI visibility"}

**What to change:** {the exact field, file, or setting — e.g. "add a `gtin` value to each
product in the feed" not "improve your product data"}

**Where:**
- {If it's a Mergado-feed-side fix: name the concrete Mergado tool/workflow — e.g. "add a rule
  via `create_batch_param_rule` mapping your supplier's EAN column to the `gtin` element" — only
  if Mergado MCP is connected and this is genuinely how it'd be done; don't invent tool calls
  that don't exist.}
- {If it's a website-side fix: name the actual file/template/plugin area — e.g. "the WooCommerce
  product template" or "your theme's category-page template" — as specifically as what was
  observed during the audit allows.}
- {If it depends on an external account/platform (Google Merchant Center, ChatGPT merchant
  portal, Perplexity merchant program, etc.): say which account is needed and that this skill
  can't complete that step directly.}

**How to verify it worked:** {a concrete, repeatable check — e.g. "reload the product page and
confirm `gtin` appears in the JSON-LD block" or "re-run `scripts/audit.sh` against this page
and check row 8"}
```

## Style notes

- One block per recommendation, clearly separated — even if the user asked for "all 5," don't
  merge them into a single undifferentiated wall of text.
- Every "what to change" must name something concrete and specific to what this store's audit
  actually found — not a templated generic instruction that would read the same for any store.
- If you're not sure a specific Mergado tool applies to the fix, say so and suggest which
  general area to look in, rather than fabricating a tool/parameter name.
- Verification steps should be things the user (or this skill, re-run) can actually check —
  not "wait and see if ChatGPT recommends you more," which isn't verifiable on demand.
