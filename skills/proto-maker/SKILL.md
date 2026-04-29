---
name: proto-maker
description: Master orchestrator. Walks the PM through stages 1-8 sequentially, asking 'ready for next stage?' at each gate. Use when starting a new idea and want guided progression. Individual stage skills ($explore, $refine, etc.) can also be invoked directly.
---

# $proto-maker — master pipeline orchestrator

## Preconditions

1. Verify `context/product.md`, `context/personas.md`, `context/constraints.md`
   exist and are non-empty. If not, tell the PM to run `$setup` first and stop.

## Process

1. Ask the PM: "New idea, or continuing an existing one?"
   - New: ask for the idea slug (or generate one from a one-liner). Run `$explore`.
   - Existing: ask which idea, list `ideas/*/` folders. Determine which stage
     they're at by checking which artifacts exist. Resume from the next stage.

2. After each stage completes, summarize what was produced and ask:
   "Ready for stage N+1 (`/<next-skill>`)? (yes / pause / re-run last stage)"
   - yes → invoke the next stage's skill internally
   - pause → tell PM how to resume later
   - re-run → invoke the same stage skill again (after warning artifacts will be overwritten)

3. Stage-by-stage routing:
   - Stage 1: `$explore` → produces `00-exploration.md`
   - Stage 2: `$refine` → produces `01-alternatives.md` (with verdict)
   - Stage 3: `$document-scope` → produces `02-scope.md`
     - If verdict is `kill` and PM doesn't override, route back to stage 1
   - Stage 4: `$build-prototypes` → produces `03-prototypes/`
   - Stage 5: `$review-prototypes` → produces `04-review-notes.md` + `CHOSEN`
     - If `CHOSEN` is `none`, route back to stage 2
   - Stage 6: `$iterate-prototype` → optional, can be skipped
   - Stage 7: `$write-user-stories` → produces `06-user-stories.md`
   - Stage 8: `$handoff` → produces `HANDOFF.md` + `handoff.zip`

4. After stage 8, congratulate the PM and remind them where to find the
   handoff package.

## Constraints

- Never bypass a stage. The artifact contracts depend on prior outputs.
- Never silently overwrite a completed stage's artifact — always confirm first.
- If the PM wants to do something proto-maker doesn't support, say so explicitly
  rather than improvising.
