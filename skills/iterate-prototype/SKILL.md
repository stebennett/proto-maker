---
name: iterate-prototype
description: Stage 6. Applies PM feedback to the chosen alternative. Snapshots the current state to .history/iter-N/, dispatches the Designer to rework, then Critic + User Advocate + Engineer to validate, then Designer to evolve once. Writes 05-iteration-log.md.
---

# /iterate-prototype — stage 6: refine the winner

## Inputs

- `ideas/<slug>/03-prototypes/CHOSEN`
- `ideas/<slug>/04-review-notes.md`
- The chosen alternative's folder

## Refuse if

- `CHOSEN` missing or contains `none` → run `/review-prototypes`
- `04-review-notes.md` missing → run `/review-prototypes`

## Process

1. Read CHOSEN, identify the alt folder.
2. Determine the next iteration number: scan `.history/iter-*` and pick the
   next free integer.
3. Snapshot the current alt folder to `ideas/<slug>/.history/iter-N/`:
   ```bash
   mkdir -p ideas/<slug>/.history/iter-N
   cp -R ideas/<slug>/03-prototypes/<alt>/. ideas/<slug>/.history/iter-N/
   ```
4. Ask the PM: "What changes do you want for iteration N?" Accept free-text;
   summarize back to confirm understanding.
5. Dispatch the `designer` subagent with: the alt folder, the change list,
   and full context. Designer edits HTML in place.
6. Dispatch `critic` + `user-advocate` + `engineer` IN PARALLEL to validate
   the rework. Their memos overwrite `<alt>/critiques/*.md` (the v2 critiques).
7. Dispatch `designer` once more to refine in light of new critiques, only
   if at least one critic flagged a substantive issue.

## Output

Append to `ideas/<slug>/05-iteration-log.md` (creating the file if missing):

```markdown
---
stage: 6
idea: <slug>
updated: <YYYY-MM-DD>
inputs: [CHOSEN, 04-review-notes.md, .history/]
---

# Iteration log for <idea title>

## Iteration N (<YYYY-MM-DD>)
**Snapshot:** .history/iter-N/
**Changes requested:** <PM's summary>
**Changes made:** <bullets from designer's report>
**New critiques:** see <alt>/critiques/*.md

```

## Done

Tell PM:
"Iteration N applied. Snapshot of pre-iteration state: `.history/iter-N/`.
Re-open the prototype in your browser to review. Run `/iterate-prototype`
again for further changes, or `/write-user-stories` when ready to hand off."
