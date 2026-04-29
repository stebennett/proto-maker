---
name: write-user-stories
description: Stage 7. Reads the chosen prototype + scope + TBDs, drafts user stories in conventional markdown format, dispatches Engineer to sanity-check feasibility. Writes 06-user-stories.md.
---

# $write-user-stories — stage 7: convert prototype to stories

## Inputs

- `ideas/<slug>/03-prototypes/CHOSEN`
- `ideas/<slug>/03-prototypes/<chosen>/index.html` and screens
- `ideas/<slug>/02-scope.md`
- `context/personas.md`

## Refuse if

- `CHOSEN` missing or `none`

## Process

1. Read scope, personas, and the chosen prototype.
2. Scan the chosen prototype's HTML for `<mark class="tbd">` elements.
   Build a list: `[{screen, tbd_text}]`.
3. For each TBD, ask the PM:
   "On screen `<screen>`: `<tbd_text>` — should this become (a) its own user
   story, (b) an acceptance criterion of an existing story, or (c) explicitly
   out-of-scope for v1?"
4. Draft user stories. Each story uses the conventional template:

```markdown
### Story: <short title>

**As a** <persona from personas.md>
**I want** <goal>
**So that** <benefit>

**Acceptance criteria**
- [ ] <observable criterion>
- [ ] <observable criterion>

**Open questions**
- <question, often from a TBD>
```

5. Size the story count to the prototype's scope. Don't pad. A 3-screen
   prototype might warrant 4–6 stories; a 10-screen prototype might warrant
   12–15. If unsure, err lower and let the PM ask for more.
6. Dispatch the `engineer` subagent with the draft stories AND the chosen
   prototype HTML. Engineer returns a feasibility-flagged version
   (e.g., "Story 3: feasibility flag — assumes background job we don't have").
7. Show the PM the engineer-flagged version. Accept their edits.

## Output

Write `ideas/<slug>/06-user-stories.md`:

```markdown
---
stage: 7
idea: <slug>
updated: <YYYY-MM-DD>
inputs: [CHOSEN, 03-prototypes/<chosen>/, 02-scope.md, context/personas.md]
---

# User stories for <idea title>

## In scope

<one or more story blocks using the template above>

## Out of scope (v1)

- <bullet, often from a TBD classified as out-of-scope>

## Engineer feasibility flags

- Story <n>: <flag>
```

## Done

Tell PM:
"User stories written to `06-user-stories.md`. Final step: `$handoff` to
package everything for engineering."
