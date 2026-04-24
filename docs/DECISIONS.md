# proto-maker — Decision Log

Captures the key architectural decisions, the alternatives considered, and the rationale. Lives in git so any machine cloning the repo has the full picture — not just *what* we chose but *why we rejected the alternatives*, so they don't quietly reappear in later iterations.

Decisions are listed in the order they were made during brainstorming. Each entry notes its load-bearing-ness: whether it's open for revisit later, or locked-in ("don't reopen without re-raising the trade-off").

---

## D1 — Runtime: Codex CLI primary, Claude Code deferred

**Decision:** Ship proto-maker in the open AGENTS.md + Skills format, targeting Codex CLI as the primary (and only v1) runtime. Claude Code support is a later-version goal.

**Alternatives considered:**
- Claude Code subagents + slash commands
- Custom app using the Anthropic SDK (web or desktop)
- Formal Claude Code plugin / Codex equivalent plugin
- Standalone orchestrator script, Slack bot, etc.

**Why:** The PM audience at Steve's organization has access to Codex / ChatGPT but not Claude. The tool must work where PMs already are. The open Skills format is platform-portable — Claude Code support should be near-free to add later, but v1 scope is Codex-only.

**Status:** Locked in for v1. Claude Code support is on the v1.1+ roadmap.

---

## D2 — No developer tooling on PM machines

**Decision:** Assume PMs running proto-maker have ONLY Codex CLI and a text editor. No git, no GitHub accounts, no package managers (npm / pip / brew / apt), no docker, no admin rights to install them.

**Why:** Steve's org grants PMs access to Codex / ChatGPT but not to developer accounts or admin install rights. This is a hard organizational constraint, not a usability preference.

**How this constraint shapes the design:**
- Installers fetch release zips via built-in tools (curl / Invoke-WebRequest), never `git clone`.
- Skills are forbidden from running `git`, `gh`, `npm`, `pip`, etc. AGENTS.md enforces this at the top of "Forbidden actions."
- Iteration history uses filesystem snapshots (`.history/iter-N/`) instead of git history.
- The `/handoff` skill produces a zip (not a pull request) as the engineering deliverable.
- Cross-platform server packaged as a Go static binary, not Python (Python isn't guaranteed on Windows) or Node (not guaranteed anywhere).

**Scope of the rule:** PM-facing runtime only. The proto-maker *maintainer* repo (this one) uses git normally.

**Status:** Locked in. Do not reopen — this is a hard constraint from Steve's organizational context.

---

## D3 — Hybrid orchestration (master skill + standalone stage skills)

**Decision:** A master `/proto-maker` skill walks the PM through stages 1→8 sequentially with confirmation gates, AND each stage is a standalone skill invocable directly.

**Alternatives considered:**
- **Monolithic master skill only** — guided but inflexible
- **Standalone skills only** — maximum flexibility but PM has to remember the sequence

**Why:** PMs aren't always linear. They want to jump back to "refine alternatives" after a prototype review, or skip ahead if the idea is already well-scoped. Hybrid supports both the guided first-run and the "just redo this one step" case.

**Status:** Open for refinement. If the master skill turns out to be rarely used during dogfooding, we could drop it in v2.

---

## D4 — Role-specialized subagents for creative tension

**Decision:** Four subagents — **Designer, Critic, User Advocate, Engineer** — provide creative tension at two stages: `/refine` (is this alternative worth prototyping?) and `/build-prototypes` (does this wireframe faithfully express the idea?).

**Alternatives considered:**
- **One general-purpose prototype subagent** producing N alternatives from the same brain
- **All conversational skills, no subagents** — cheapest, but serial and no internal tension
- **More roles** — Copywriter, Product Strategist

**Why:** Steve's explicit rationale: *"I feel like we're missing this tension in our process at the moment."* His current PM process lacks productive friction between perspectives. Internalizing it in the tool — rather than depending on the PM to produce it — elevates every prototype to a defensible one without extra PM labor.

**What we rejected and why:**
- **Copywriter role** — valuable but lower-leverage for wireframes where polish isn't the goal. Can be added in v1.1 if the existing roles feel thin.
- **Product Strategist role** — rejected because context would be too thin to make the role substantive. The pattern requires concrete input the PM can provide (personas, constraints, scope text); strategy requires context that usually lives only in someone's head.

**Status:** **Locked in. Don't collapse these four roles into a single general-purpose subagent for "efficiency" without re-raising the trade-off with Steve.** The tension is the product.

---

## D5 — Context injection is first-class

**Decision:** Before any per-idea work runs, the PM populates three files via `/setup`: `context/product.md`, `context/personas.md`, `context/constraints.md`. Every stage skill and subagent reads these first. Every skill refuses to run if they're missing or empty.

**Why:** Without concrete product / persona / constraint text, the User Advocate subagent has no persona to channel and the Engineer subagent has no constraints to flag against. The critics collapse into generic churn. This was called out as a critical gap during brainstorming (*"context injection is critical"* — Steve).

**Status:** Locked in. Do not relax the "refuse to proceed without context" gate.

---

## D6 — Clean minimal wireframes (Pico.css), not sketch-style

**Decision:** Prototypes use Pico.css + small components.css for "clean minimal" styling — looks like a real, simple UI.

**Alternatives considered:**
- **A) Low-fi grayscale** (Figma wireframe kit look) — best at focusing reviewers on scope
- **B) Hand-drawn / Balsamiq-style** — strong "this is a rough idea" signal
- **C) Clean minimal (Pico.css)** — credible with execs

**Why (Steve's rationale):** Target audience includes execs, and sketch-style wireframes undermine credibility in that room. The trade-off — reviewers being tempted to give feedback on colors / spacing instead of scope — is real and was knowingly accepted.

**Mitigation for the accepted risk:** `/review-prototypes` explicitly frames the review with *"focus on scope, not colors/spacing."*

**Status:** **Locked in. Don't re-suggest Balsamiq or low-fi styling as a "fix" for feedback drift.** Steve saw the trade-off and chose C deliberately.

---

## D7 — Multi-page HTML, JS allowed for explanatory interactions

**Decision:** Each prototype screen is its own `.html` file linked via `<a href>`. In-page JavaScript is allowed ONLY when it helps *explain* the feature (modals, tabs, dropdowns). Never to simulate backend behavior.

**Alternatives considered:**
- Single-page HTML with JS screen-routing (one file to email, harder to grow)
- Single-page with hash routing (`#home`, `#settings`)
- SPA framework (React/Vue) — rejected outright; violates the "no build step" principle

**Why:** Multi-page matches how real apps work, which makes user-story extraction easier (each screen ≈ one story or part of a flow). Browser back/forward works naturally. Scales to bigger flows. JS-for-explanation rule (added by Steve mid-brainstorm) lets the Designer show interactive patterns — a modal launching, a tab switching — that would otherwise be handwaved.

**Status:** Open. If a real prototype benefits from hash-routing for deep linking, we can revisit.

---

## D8 — Per-idea workspace in a standalone ideas repo

**Decision:** Each idea gets its own folder `ideas/<slug>/` containing all artifacts, prototypes, critiques, and the handoff package. Ideas live in a standalone ideas-repo owned by the PM, separate from any product codebase.

**Alternatives considered:**
- Centralized folders by type (`explorations/`, `scopes/`, `prototypes/`, `stories/`)
- Ideas as subfolders of the product codebase
- Flat — everything in the working directory

**Why:** One folder = one idea's full journey. Easy to share (zip the folder), easy to archive, easy to diff iterations. A standalone ideas-repo keeps prototyping artifacts from polluting product source trees, and matches the PM's workflow (they're producing for engineering, not editing engineering code).

**Status:** Locked in.

---

## D9 — Tension at BOTH refinement and prototyping stages

**Decision:** The four critique subagents are invoked at TWO distinct stages:
- **`/refine` (stage 2)** — attacks the alternative space: is this the right thing to build? Produces a verdict (`proceed | revise | kill`).
- **`/build-prototypes` (stage 4)** — attacks each prototype individually: does this wireframe faithfully express the idea?

**Alternative considered:** Tension at only one of the two stages.

**Why:** Refinement-stage tension catches bad alternatives before the PM wastes a prototyping round on them. Prototype-stage tension catches handwaving and feasibility issues before the PM wastes a review round. Both high-leverage; cutting either would re-introduce the gap that motivated the tension mechanism.

**Status:** Locked in. Removing tension at either stage would undermine D4.

---

## D10 — Go microserver, cross-compiled, unsigned for v1

**Decision:** A tiny Go HTTP server (`proto-maker-server`, ~100 LOC, stdlib only) provides localhost static serving + annotation POST endpoints for the wireframe overlay. Cross-compiled to Windows/macOS/Linux binaries. **Unsigned for v1.**

**Alternatives considered:**
- **Python stdlib `http.server`** — Python 3 ships on macOS/Linux but not guaranteed on Windows (where most PMs live). Installing Python pre-req adds friction.
- **Node.js script** — Node isn't on PM machines and can't be assumed.
- **Bundled runtime (Deno / Bun)** — large binaries (~80–100MB each).
- **Signed binaries from day one** — Authenticode cert is ~$200–500/year + ownership; Apple notarization is $99/year + workflow.

**Why:** Go binaries are single-file (~5-10MB), zero-dependency, cross-compile trivially (`GOOS=... GOARCH=... go build`). Perfect fit for the no-dev-tooling constraint.

**Unsigned trade-off:** Windows SmartScreen and macOS Gatekeeper will warn users on first run. The bypass is a 2-click process. Acceptable for internal rollout; documented in README with screenshots-placeholder.

**Status:** Signing is a known deferred item for v1.1. The "unsigned-with-documented-workaround" choice is explicitly Steve's for v1.

---

## D11 — File-based state (no hidden in-memory handoffs)

**Decision:** Every stage reads and writes ONLY files. Inter-stage communication is always via the idea folder. No orchestrator holds state between stage invocations.

**Why:** A PM can stop anywhere, close their laptop, and resume later without ceremony. Also makes contract testing trivial (assert file structure, not runtime behavior). Also means stages can be rerun independently without rebuilding context.

**Status:** Locked in architectural principle. Any future "context memory" feature must use a file, not runtime state.

---

## D12 — Four sub-plans, not one monolithic plan

**Decision:** Split the implementation into 4 plans that each produce working, testable software:
1. Go microserver
2. Wireframe template
3. Skills & agents
4. Installer & release tooling

**Why:** Per `superpowers:writing-plans` guidance: a single plan must produce end-to-end working software; a multi-subsystem spec yields one plan per subsystem. The four subsystems are independently testable, have clean interfaces, and decouple risk.

**Dependency order:** 1 and 2 parallel → 3 → 4.

**Status:** Structural. Not expected to change.

---

## Summary — what NOT to reopen without re-discussing

These are the choices where a future session should re-raise the trade-off with Steve before changing direction, not silently reverse:

| Decision | Reason to lock |
|---|---|
| D1 — Codex primary | Audience-driven |
| D2 — No dev tooling on PM machines | Hard org constraint |
| D4 — Four role-specialized subagents | Identified by Steve as the missing piece |
| D5 — Context injection required | Identified as critical gap |
| D6 — Clean minimal wireframes | Trade-off knowingly accepted |
| D9 — Tension at both refine AND build | Weaken either and D4 collapses |
