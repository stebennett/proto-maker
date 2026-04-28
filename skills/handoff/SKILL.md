---
name: handoff
description: Stage 8. Assembles HANDOFF.md (table of contents + exec summary) and packages the entire idea folder into handoff.zip for engineering. Reads all prior artifacts.
---

# /handoff — stage 8: package for engineering

## Inputs

- All prior artifacts in `ideas/<slug>/`

## Refuse if

- Any of `00-exploration.md`, `02-scope.md`, `06-user-stories.md`, or `CHOSEN` is missing.

## Process

1. Read all artifacts. Verify the chosen prototype exists.
2. Assemble `HANDOFF.md` at `ideas/<slug>/HANDOFF.md`:

```markdown
---
stage: 8
idea: <slug>
updated: <YYYY-MM-DD>
inputs: [00-exploration.md, 02-scope.md, 03-prototypes/CHOSEN, 04-review-notes.md, 06-user-stories.md]
---

# Engineering handoff: <idea title>

## Exec summary
<3-5 sentences. Pull from 00-exploration.md "One-liner" + 02-scope.md "Hypothesis".>

## Hypothesis being tested
<from 02-scope.md>

## Success criteria
<from 02-scope.md>

## Personas served
<from 02-scope.md>

## Chosen prototype
- Folder: `03-prototypes/<chosen>/`
- Open: `03-prototypes/<chosen>/index.html`

## User stories
See `06-user-stories.md` (<count> stories).

## Open questions
<consolidated TBDs that became open questions in stories, plus any from
review/iteration logs>

## Engineering checklist (before estimating)
- [ ] Read scope, hypothesis, success criteria
- [ ] Click through chosen prototype, including TBD callouts
- [ ] Read user stories — each story's "Open questions" section
- [ ] Confirm constraints from `context/constraints.md` are satisfied
- [ ] Identify integration points with existing systems
- [ ] T-shirt size each story
```

3. Snapshot `context/` into the idea folder so the handoff is self-contained:
   ```bash
   mkdir -p ideas/<slug>/context-snapshot
   cp context/product.md context/personas.md context/constraints.md \
     ideas/<slug>/context-snapshot/
   ```

4. Package the entire idea folder into `ideas/<slug>/handoff.zip`:
   ```bash
   cd ideas/<slug>
   # Use Python's zipfile if `zip` is unavailable on the PM's machine.
   python3 -c "
   import zipfile, os
   with zipfile.ZipFile('handoff.zip', 'w', zipfile.ZIP_DEFLATED) as z:
       for root, dirs, files in os.walk('.'):
           for f in files:
               if f == 'handoff.zip': continue
               p = os.path.join(root, f)
               z.write(p, p)
   "
   ```

## Validation

- HANDOFF.md exists, has all H2 sections populated
- handoff.zip exists, is non-empty
- Unzipping handoff.zip into a temp dir and opening
  `<temp>/03-prototypes/<chosen>/index.html` should work

## Done

Tell PM:
"Handoff package ready:
- Read: `ideas/<slug>/HANDOFF.md`
- Share: `ideas/<slug>/handoff.zip` (attach to email or upload to Drive/SharePoint)

Engineering can extract the zip anywhere and have everything they need to start
estimating."
