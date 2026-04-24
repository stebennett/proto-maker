# Resuming proto-maker work

You (or a future version of you) is picking this project up after a break, a context loss, or a fresh session. This doc is the shortest path back to productivity.

## 60-second orientation

1. Read [`docs/superpowers/README.md`](superpowers/README.md) — what proto-maker is + dependency order of the 4 plans.
2. Open [`TODOS.md`](../TODOS.md) at the repo root — find the first unchecked task.
3. Open the corresponding plan file in `docs/superpowers/plans/` — navigate to that task.
4. Execute the task's steps. Commit per the step instructions.
5. Mark the checkbox in TODOS.md and commit it.

That's it.

## Where everything lives

| You want... | Go to |
|---|---|
| Why we built this and what v1 does | `docs/superpowers/specs/2026-04-24-proto-maker-design.md` |
| The next task to execute | `TODOS.md` |
| Step-by-step for a specific plan | `docs/superpowers/plans/2026-04-24-proto-maker-<subsystem>.md` |
| An index of everything | `docs/superpowers/README.md` |
| Decision rationale + "why we rejected X" | `docs/DECISIONS.md` |
| User preferences (primary-machine only) | memory files at `~/.claude/projects/-Users-stevebennett-code-github-proto-maker/memory/` |

## State check at resume time

Run these from the repo root to sanity-check where you are:

```bash
# What's committed?
git log --oneline

# What's changed but not committed?
git status

# How far through execution are we?
grep -c "^- \[x\]" TODOS.md  # completed
grep -c "^- \[ \]" TODOS.md  # remaining
```

## Rules of engagement (do not violate)

These were locked in during brainstorming. Full rationale + alternatives considered for each is in `docs/DECISIONS.md`. Read there before changing direction on any of them.

1. **PMs do not have developer tooling.** No git, no npm, no pip, no gh. (D2)
2. **Codex CLI is the primary runtime.** Claude Code support is deferred to v1.1. (D1)
3. **Role-specialized subagents (Designer, Critic, User Advocate, Engineer) are the tension mechanism.** Don't collapse them into a single general-purpose subagent without re-raising the trade-off with Steve. (D4)
4. **Clean minimal wireframe styling (Pico.css), not Balsamiq/sketchy.** Trade-off was knowingly accepted. (D6)
5. **Unsigned binaries for v1.** Signing is v1.1. (D10)
6. **`context/*.md` is required before any per-idea work runs.** `/setup` populates it; every other skill refuses to run without it. (D5)
7. **Tension must live at BOTH `/refine` AND `/build-prototypes`.** Removing it from either stage undermines D4. (D9)

## If you find yourself adding a new decision

1. Put it in a spec section if it changes the design — bump the spec file's frontmatter `status` to indicate it's been updated.
2. If it's a preference that should survive future sessions, add a memory file under the memory/ directory (see existing ones as examples).
3. If it's a task to execute, add it to the appropriate plan AND to TODOS.md.

## Sanity checks before declaring "done"

- `TODOS.md` has zero unchecked boxes
- `docs/superpowers/specs/2026-04-24-proto-maker-design.md` §12 success criteria are met
- Dogfood walkthrough (Plan 3, Task 18) runs end-to-end on a Windows VM
- A GitHub release (or internal equivalent) has the 4 per-platform zips attached
