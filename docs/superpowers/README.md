# proto-maker — Superpowers Documentation Index

One-stop pointer for everyone (or future-you) picking up this project.

## Start here

**What is proto-maker?**
A portable set of Codex CLI skills + subagents + a tiny Go microserver that walks a Product Manager through an 8-stage pipeline: `explore → refine → document-scope → build-prototypes → review-prototypes → iterate-prototype → write-user-stories → handoff`. Output is a clickable wireframe prototype and an engineering handoff package.

**Who is it for?**
PMs at organizations where Codex CLI is available but developer tooling (git, npm, pip, etc.) is not.

## Documents

### Design spec
- [2026-04-24-proto-maker-design.md](specs/2026-04-24-proto-maker-design.md) — full v1 design, 12 sections. Start here before reading any plan.

### Execution plans (four sub-plans)
1. [Plan 1 — Go microserver](plans/2026-04-24-proto-maker-server.md) — 10 tasks
2. [Plan 2 — Wireframe template](plans/2026-04-24-proto-maker-template.md) — 10 tasks
3. [Plan 3 — Skills & agents](plans/2026-04-24-proto-maker-skills.md) — 18 tasks (biggest)
4. [Plan 4 — Installer & release tooling](plans/2026-04-24-proto-maker-installer.md) — 7 tasks

### Operational
- [TODOS.md](../../TODOS.md) — execution tracker, grouped by plan. This is your "what's next" file.
- [docs/RESUMING.md](../RESUMING.md) — how to pick the project back up if context is lost.

## Dependency order

```
Plan 1 (server) ──┐
                  ├─→ Plan 3 (skills — uses Plan 1 via /preview + Plan 2 via /build-prototypes)
Plan 2 (template)─┘                                                                              ──→ Plan 4 (installer — packages all of the above)
```

Plans 1 and 2 are independent and can run in parallel. Plan 3 needs both complete. Plan 4 needs all three complete.

## Key architecture decisions (skim these if you only have 5 minutes)

1. **Open AGENTS.md + Skills format** — portable across Codex CLI (primary), Claude Code (deferred to v1.1), and any future platform adopting the format. (Spec §3)
2. **Role-specialized subagents** — Designer, Critic, User Advocate, Engineer. Creative tension is internalized rather than relying on the PM to produce it. (Spec §4.6)
3. **Tension at TWO stages** — `/refine` (is this alternative worth building?) and `/build-prototypes` (does this prototype express the idea?). Spec §5.4, §5.5.
4. **Context as first-class input** — `context/product.md`, `context/personas.md`, `context/constraints.md` are populated once per product via `/setup` and read by every stage. Without them, User Advocate and Engineer subagents have nothing to push back from. (Spec §3 critical gap #1)
5. **No git, no dev tooling on PM machines** — installers use curl/Invoke-WebRequest, not git clone. Iteration history is `.history/iter-N/` filesystem snapshots. (Spec §8.3)
6. **Clean minimal wireframes (Pico.css), not sketchy** — more credible with execs despite the design-drift risk. Steve made this call explicitly. (Spec §6.3)
7. **Go microserver, cross-compiled, unsigned v1** — single binary per platform; documented SmartScreen / Gatekeeper workaround for v1. (Spec §7)
8. **File-based state** — every stage reads and writes only files. A PM can abandon work mid-pipeline, close their laptop, and resume by running the next stage. (Spec §5.1)

## Ship gate

proto-maker v1 ships when every task in `TODOS.md` is checked AND the dogfood walkthrough (Plan 3, Task 18) runs end-to-end on a Windows VM against an installed release zip. See spec §12 for the full success criteria.
