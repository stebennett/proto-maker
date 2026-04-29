---
name: setup
description: One-time bootstrap of context/product.md, context/personas.md, context/constraints.md for a product. Walks the PM through a structured interview. Run once per product, not per idea. Required before any other proto-maker skill runs.
---

# $setup — one-time product context bootstrap

## When to use

Run this once per product the PM works on, before invoking `$proto-maker` or
any other proto-maker skill for the first time in this ideas repo.

## What you do

You walk the PM through three short interviews and produce three files:

1. `context/product.md` — what the product is, positioning, top features
2. `context/personas.md` — 1–4 target user personas with goals + frustrations
3. `context/constraints.md` — non-negotiable tech, brand, and policy constraints

## Process

1. Check if `context/` exists. If yes, ask: "It looks like you've already set up
   context. Want to overwrite, append, or cancel?" and act accordingly.
2. Otherwise, create `context/` and walk three interviews in order.

### Interview 1: product

Ask, ONE question at a time:
- What's the product called?
- One sentence: what does it do for whom?
- What are 2–4 top features that already exist?
- Anything about positioning the rest of us should know? (competitors,
  unique selling points)

Write `context/product.md` with sections: `## Name`, `## One-liner`,
`## Existing top features`, `## Positioning`.

### Interview 2: personas

Ask: "How many distinct user types do you serve? (1–4 is typical.)"

For each persona:
- Persona name (job title or short label)
- One sentence: who they are
- Top 2–3 things they're trying to do
- Top 2–3 things that frustrate them today

Write `context/personas.md` with one `## <persona name>` block per persona,
each with `### Who`, `### Goals`, `### Frustrations`.

### Interview 3: constraints

Ask: "What MUST any new feature respect?"

Probe specifically:
- Tech stack constraints? (e.g., "must work in IE11", "no third-party JS")
- Brand or visual constraints? (e.g., "must use the design system")
- Policy / compliance constraints? (e.g., "no PII in URLs")
- Operational constraints? (e.g., "must work offline")

Write `context/constraints.md` with sections `## Technical`, `## Brand`,
`## Policy / Compliance`, `## Operational`. Each section: bullets, or
"None specified" if the PM has nothing.

## Validation before exit

Before reporting success:
- All three files exist
- Each is non-empty (> 100 bytes)
- None contains the literal string "TODO" or "TBD"

If any check fails, tell the PM what's missing and re-prompt the relevant
section.

## Done

When all three files pass validation, write:
"Context setup complete. You can now run `$proto-maker` to start your first idea,
or invoke any individual stage skill directly."
