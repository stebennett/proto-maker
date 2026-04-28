---
name: explore
description: Stage 1. Captures the PM's raw idea via a structured exploration interview. Reads context/. Writes ideas/<slug>/00-exploration.md.
---

# /explore — stage 1: idea exploration

## Inputs

- `context/product.md`, `context/personas.md`, `context/constraints.md`
- The PM's raw idea (you'll ask for it)

## Refuse if

- `context/` is missing or any file is empty → tell PM to run `/setup`.

## Process

1. Ask: "What's the idea, in one sentence? (You can refine it as we go.)"
2. Convert the idea to a kebab-case slug (e.g., "smart-onboarding-flow"). Confirm
   with the PM, offering to adjust.
3. Create `ideas/<slug>/`.
4. Walk the exploration interview, ONE question at a time:
   - What problem does this solve?
   - Whose problem is it? (Reference personas from `context/personas.md`.)
   - How is this handled today? (Workaround, manual process, not at all?)
   - What triggered this idea? (Customer ask, support pattern, exec direction, instinct?)
   - What's the smallest version of this that would still be valuable?
   - What's the biggest version? What would "ambitious" look like?
   - What's NOT the goal here — what should we explicitly avoid scoping in?

5. Write `ideas/<slug>/00-exploration.md`:

```markdown
---
stage: 1
idea: <slug>
updated: <YYYY-MM-DD>
inputs: [context/]
---

# Exploration: <idea title>

## One-liner
<PM's one sentence>

## Problem
<from the interview>

## Whose problem
<persona references from personas.md>

## Today's workaround
<...>

## Trigger
<...>

## Smallest valuable version
<...>

## Ambitious version
<...>

## Out of scope
<...>
```

## Validation

- Frontmatter present with all 4 fields
- All 7 H2 sections present, none empty (write `(unspecified)` only if PM
  explicitly skipped)

## Done

Tell PM: "Exploration captured to `ideas/<slug>/00-exploration.md`. When ready
to refine, run `/refine` or `/proto-maker` to continue the pipeline."
