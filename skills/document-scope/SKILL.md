---
name: document-scope
description: Stage 3. Forces the PM to state hypothesis, success criteria, main risk, and personas served. Reads 01-alternatives.md. Writes 02-scope.md.
---

# $document-scope — stage 3: hypothesis + criteria

## Inputs

- `ideas/<slug>/01-alternatives.md`
- `context/personas.md` (for persona names)

## Refuse if

- `01-alternatives.md` missing (run `$refine`)

## Verdict gate

1. Parse the verdict block at the end of `01-alternatives.md`.
2. If `recommendation: kill`, print the justification to the PM and ask:
   "The critic recommended killing this alternative space. Override and continue
   anyway? (yes/no)"
3. If yes, record the override in the scope doc's frontmatter (`override_kill: true`).
4. If no, suggest re-running `$explore` and stop.

## Process

Walk the PM through 4 mandatory questions, ONE at a time:

### Hypothesis
"In one sentence, complete this: 'This prototype is successful if stakeholders
conclude ___.'" (Refuse vague answers like "users like it" — push for an
observable conclusion.)

### Success criteria
"What would you have to OBSERVE — in stakeholder reactions, in user-test
behavior, in metric movements — to know the hypothesis is supported?" Capture
as bullets.

### Main risk being tested
"What assumption underpins this idea that you're least sure of?" One sentence.

### Personas served
"Which personas (from `context/personas.md`) does this serve?" Validate the
names against personas.md — refuse persona names that don't exist there.

## Output

Write `ideas/<slug>/02-scope.md`:

```markdown
---
stage: 3
idea: <slug>
updated: <YYYY-MM-DD>
inputs: [01-alternatives.md, context/personas.md]
override_kill: <true|false>
---

# Scope for <idea title>

## Hypothesis
<one sentence>

## Success criteria
- <bullet>
- <bullet>

## Main risk being tested
<one sentence>

## Personas served
- <persona name from personas.md>
```

## Validation before write

- All 4 H2 sections present and non-empty
- Persona names match entries in `context/personas.md` exactly

## Done

Tell PM: "Scope locked to `02-scope.md`. Next step: `$build-prototypes`."
