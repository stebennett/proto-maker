---
name: review-prototypes
description: Stage 5. Captures PM and stakeholder feedback on the built prototypes, picks a winning alternative (or 'none'), writes 04-review-notes.md and the CHOSEN pointer file.
---

# $review-prototypes — stage 5: capture feedback, pick winner

## Inputs

- `ideas/<slug>/03-prototypes/alt-*/`
- `ideas/<slug>/03-prototypes/alt-*/annotations/*.json` (optional — server or pasted-in)

## Refuse if

- `03-prototypes/` missing (run `$build-prototypes`)

## Process

1. Frame the review for the PM:
   "Reminder: the prototypes use clean wireframes. We're focused on whether
   each alternative expresses the IDEA — scope, flow, missing pieces — not on
   colors, spacing, or polish."

2. For each alternative, walk a structured review:
   - Show the PM the alt's `DESIGN-LOG.md` summary (or summarize it).
   - List any annotations from `<alt>/annotations/*.json` (parse JSON, show
     `screen`, `note`, `author`).
   - Ask the PM: "Your reaction? (free text)"
   - Ask: "What would have to be true for this to be the winner?"

3. Ask if there were stakeholder reviews captured outside the system. If yes,
   ask the PM to paste structured JSON (from the offline-mode "Copy notes"
   button) or freetext notes. Append to the alternative's annotations folder
   if structured.

4. Ask: "Which alternative wins? (Choices: <list>; or `none` to revisit refinement.)"

## Output

Write `ideas/<slug>/04-review-notes.md`:

```markdown
---
stage: 5
idea: <slug>
updated: <YYYY-MM-DD>
inputs: [03-prototypes/, annotations/]
---

# Review notes for <idea title>

## Alternative 1: <angle>
**Annotations:** <count>
**PM reaction:** <text>
**Conditions to win:** <text>

## Alternative 2: <angle>
...

## Alternative 3: <angle>
...

## Decision
**Chosen:** <alt folder name>, or `none`
**Rationale:** <one paragraph>

## Stakeholder feedback summary
<short summary of any external feedback the PM provided>
```

Also write `ideas/<slug>/03-prototypes/CHOSEN`:
- One line: the chosen alternative's folder name (e.g., `alt-2-guided`)
- Or one line: `none`

## Done

If chosen is `none`, tell PM:
"None of the alternatives won. Suggested next step: re-run `$refine` to explore
new angles, or `$iterate-prototype` if a small fix would salvage one of them."

If chosen is a folder name, tell PM:
"Winner recorded: `<folder>`. Next step: `$iterate-prototype` to refine the
chosen prototype, or skip directly to `$write-user-stories` if it's
ready as-is."
