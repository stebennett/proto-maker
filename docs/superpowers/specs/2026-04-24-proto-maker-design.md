---
title: proto-maker — Design Spec
date: 2026-04-24
status: draft
author: Steve Bennett (with Claude)
---

# proto-maker — Design Spec

## 1. Purpose

proto-maker is a portable set of skills and subagents that helps a Product Manager turn a raw idea into an engineering-ready handoff. The pipeline runs in [Codex CLI](https://openai.com/codex) on the PM's own machine and produces:

- A scoped, hypothesis-framed idea document
- Three clickable wireframe prototypes (alternatives)
- Multi-role critiques with an auditable evolution log
- A chosen prototype with a refined iteration
- A set of user stories plus an engineering handoff package

The prototypes are **static HTML files styled as clean minimal wireframes**, designed to surface scope questions rather than design polish. The pipeline deliberately injects tension at the points where PMs typically have blind spots: refinement (is this idea worth prototyping?) and prototype review (does the wireframe faithfully express the idea?).

## 2. Non-Goals

- Not a high-fidelity design tool. Prototypes are wireframes, not pixel-perfect mockups.
- Not a research platform. proto-maker does not plan or run user tests in v1.
- Not a retrospective tool. Tracking what engineering eventually built is out of scope.
- Not a backend simulator. Prototypes are static HTML; no mock APIs or simulated data flows.
- No git / developer tooling assumed on PM machines. The tool must work without them.
- Not a multi-user collaboration tool. Single PM per idea.

## 3. Platforms & Audiences

**Primary runtime:** Codex CLI. Most PMs are on Windows; proto-maker must work natively on Windows without WSL.

**Supported platforms for v1:**
- Windows 10/11 (amd64) — primary test target
- macOS (arm64 and amd64) — should work, lighter testing
- Linux (amd64) — should work, lighter testing

**Claude Code support:** Deferred to a later version. The open Skills + AGENTS.md format should make Claude Code support near-free, but it is not a v1 shipping constraint.

**Audiences:**
- **Product Managers** (primary): install proto-maker once, use it repeatedly across ideas. Not assumed to be technical.
- **Stakeholders** (secondary, no install): receive a zipped prototype bundle and click through it in a browser. Never see the server or any tooling.
- **Engineering** (secondary, no install): receive a `HANDOFF.md` + zip with scope, stories, and a clickable prototype.

## 4. Architecture

### 4.1 Two Distinct Repositories

1. **proto-maker source repo** (this repo). Contains the skills, agents, templates, and Go server source. Shipped as release artifacts.
2. **PM's ideas repo(s)**. Created and owned by the PM. Contains product context and per-idea work. proto-maker installs into the user's platform-scoped skills location; the PM's ideas repo itself does not vendor proto-maker.

### 4.2 Proto-Maker Source Repo Layout

```
proto-maker/
  AGENTS.md                    # the constitution (PM persona, conventions, forbidden actions)
  skills/
    proto-maker/               # master orchestration skill
    setup/                     # one-time context bootstrap
    preview/                   # start local server
    explore/                   # stage 1
    refine/                    # stage 2
    document-scope/            # stage 3
    build-prototypes/          # stage 4
    review-prototypes/         # stage 5
    iterate-prototype/         # stage 6
    write-user-stories/        # stage 7
    handoff/                   # stage 8
  agents/
    designer/                  # produces prototypes, evolves on critique
    critic/                    # challenges assumptions, verdict authority in refine
    user-advocate/             # attacks from persona perspective
    engineer/                  # attacks feasibility, flags TBDs
  templates/
    wireframe-base/            # Pico.css + components.css + annotation overlay
      index.html
      pico.min.css             # vendored
      components.css           # mock-nav, mock-table, mock-modal, mark.tbd
      annotations.js           # dual-mode overlay (online/offline)
  server/                      # Go source for proto-maker-server
    main.go
    go.mod
  scripts/
    build-release.sh           # cross-compiles binaries and zips release artifacts
  install.sh                   # macOS/Linux installer
  install.ps1                  # Windows installer
  README.md
  docs/
    superpowers/
      specs/
        2026-04-24-proto-maker-design.md   # this doc
```

### 4.3 PM's Ideas Repo Layout

```
my-product-ideas/
  AGENTS.md                    # thin pointer to proto-maker's constitution
  context/                     # populated by $setup, one-time per product
    product.md
    personas.md
    constraints.md
  ideas/
    <idea-slug>/
      00-exploration.md
      01-alternatives.md       # ends with YAML verdict block
      02-scope.md              # hypothesis + success criteria + main risk + personas served
      03-prototypes/
        index.html             # landing page comparing the 3 alternatives
        CHOSEN                 # plain-text pointer, written by $review-prototypes
        alt-1-<angle>/
          index.html
          screen-*.html
          DESIGN-LOG.md
          critiques/
            critic.md
            user-advocate.md
            engineer.md
          annotations/         # populated by server or pasted-in JSON
        alt-2-<angle>/
        alt-3-<angle>/
      04-review-notes.md
      05-iteration-log.md
      .history/                # iteration snapshots (replaces git for PM use)
        iter-1/
        iter-2/
      06-user-stories.md
      HANDOFF.md               # written by $handoff
      handoff.zip              # written by $handoff
```

### 4.4 Orchestration Model

Hybrid. A master skill (`$proto-maker`) walks the PM through stages 1→8, pausing for confirmation at each gate. Each stage is also a standalone skill the PM can invoke directly to rerun or jump around. Stage-to-stage communication is always via files; no hidden state.

### 4.5 Primitives

- **Skills** — conversational stages (explore, refine, scope, review, iterate, stories, handoff) live in the main context where the PM is in the loop.
- **Subagents** — prototype generation and critique run in isolated context via the Agent tool, returning condensed outputs (HTML or critique memos). Never return full reasoning transcripts.

### 4.6 The Four Subagents

| Subagent | Reads | Returns |
|---|---|---|
| Designer | context/, scope, and (for critique rounds) peer critiques | wireframe HTML + DESIGN-LOG contribution |
| Critic | context/, scope, designer's v1 | ~150–400 word memo challenging assumptions and scope |
| User Advocate | context/personas.md, scope, designer's v1 | ~150–400 word memo from the target persona's POV |
| Engineer | context/constraints.md, scope, designer's v1 | ~150–400 word memo on feasibility and handwaving |

Critiques are independent and parallel. No inter-subagent debate; tension comes from the PM reading multiple views side-by-side and from the Designer's evolution pass.

## 5. The Pipeline

### 5.1 One-Time Setup: `$setup`

Not in the stage sequence. Walks the PM through an interview to populate `context/product.md`, `context/personas.md`, `context/constraints.md`. The master `$proto-maker` skill refuses to proceed until these files exist and are non-empty.

### 5.2 One-Time Per Session: `$preview`

Not in the stage sequence. Starts `proto-maker-server` as a background process serving the current ideas repo. Walks port 4788 → 4789 → 4790 if 4788 is taken. Reports the URL. Idempotent — detects an already-running server and reports its URL rather than double-starting.

### 5.3 Stages 1–8

| # | Skill | Reads | Writes | Subagents |
|---|---|---|---|---|
| 1 | `$explore` | context/ + PM's raw idea | `00-exploration.md` | none |
| 2 | `$refine` | context/ + 00-exploration.md | `01-alternatives.md` (with verdict) | Critic, User Advocate, Engineer |
| 3 | `$document-scope` | 01-alternatives.md | `02-scope.md` | none |
| 4 | `$build-prototypes` | context/ + 02-scope.md | `03-prototypes/alt-*/` + index.html | Designer × N (parallel), then Critic + User Advocate + Engineer × N (parallel), then Designer evolves |
| 5 | `$review-prototypes` | 03-prototypes/ + annotations/ | `04-review-notes.md` + `03-prototypes/CHOSEN` | none |
| 6 | `$iterate-prototype` | CHOSEN + 04-review-notes.md | updated alt + `05-iteration-log.md` + `.history/iter-N/` | Designer (rework), then Critic + User Advocate + Engineer (validate the rework, same panel as stage 4) |
| 7 | `$write-user-stories` | CHOSEN + 02-scope.md + TBDs | `06-user-stories.md` | Engineer (sanity) |
| 8 | `$handoff` | all prior artifacts | `HANDOFF.md` + `handoff.zip` | none |

**Default alternatives count (stage 4):** 3. Overridable via skill argument.

**Master skill `$proto-maker`:** drives stages 1→8 sequentially, asking "ready for stage N+1?" at each gate. Does not bypass any stage. Checks `context/` is populated before starting stage 1.

### 5.4 Stage 4 Evolution Flow (the key tension mechanism)

For each of N alternatives, in parallel:

```
Designer produces v1 HTML + brief rationale
    ↓
Critic, User Advocate, Engineer each produce an independent critique memo
    ↓
Designer reads all three memos and produces v2 — the shipped prototype
    ↓
Designer writes DESIGN-LOG.md (rationale, critiques summary, what changed, what was ignored, unresolved tensions)
```

Only v2 is shipped. v1 is transient. The `DESIGN-LOG.md` prose captures what changed.

### 5.5 Critic Verdict in `$refine`

`01-alternatives.md` ends with a fenced YAML block:

```yaml
recommendation: proceed | revise | kill
justification: |
  Short prose explaining the verdict.
```

If verdict is `kill`, `$document-scope` prints the verdict and requires explicit PM override to proceed. The override is recorded in `02-scope.md`.

### 5.6 Winner Selection in `$review-prototypes`

Produces two outputs: the `04-review-notes.md` markdown doc AND the `03-prototypes/CHOSEN` pointer file. `CHOSEN` contains a single line: either the winning alternative folder name (e.g., `alt-2-guided`) or `none` (which routes back to `$refine`). Subsequent stages (6, 7, 8) refuse to run unless `CHOSEN` exists and is not `none`.

### 5.7 Handoff Package

`$handoff` produces:

- `HANDOFF.md` at the idea root — exec summary, hypothesis, personas served, chosen prototype pointer, user stories, open questions (extracted from remaining TBDs), engineering sign-offs checklist.
- `handoff.zip` containing the entire idea folder (including context snapshot) so engineering can open it standalone without the PM's full environment.

## 6. Artifacts — Format Conventions

### 6.1 Markdown Frontmatter

Every stage artifact starts with YAML frontmatter:

```yaml
---
stage: 2
idea: smart-onboarding-flow
updated: 2026-04-24
inputs: [context/, 00-exploration.md]
---
```

Stage skills parse frontmatter to validate inputs; they do not heuristically scan document bodies.

### 6.2 `02-scope.md` Required Sections

H2 headings (skill refuses to save with any blank):

- `## Hypothesis` — one sentence: "This prototype succeeds if stakeholders conclude X."
- `## Success criteria` — bulleted, observable signals.
- `## Main risk being tested` — the assumption most likely to be wrong.
- `## Personas served` — references names from `context/personas.md`.

### 6.3 Wireframe HTML

- Base: Pico.css (vendored, no CDN) + `components.css` for mock primitives.
- Wireframe patterns: `.mock-nav`, `.mock-sidebar`, `.mock-content`, `.mock-button`, `.mock-input`, `.mock-table`, `.mock-modal`.
- TBDs: `<mark class="tbd">assumes SSO is configured</mark>` — visually distinct, greppable.
- Multi-page via `<a href>`. In-page JS allowed for interactions that *explain* the feature (modals, tabs, dropdowns); never for simulated backend behavior.
- `annotations.js` loaded on every screen. Dual-mode:
  - Probes `GET /__ping__` on load.
  - If server present → POSTs annotations to `/ideas/<slug>/03-prototypes/<alt>/annotations/<screen>-<ts>.json`.
  - If server absent → persists to `localStorage`, exposes "Copy notes" button that places structured JSON on the clipboard.

### 6.4 Annotation JSON Shape

```json
{
  "screen": "screen-2.html",
  "path": "ideas/smart-onboarding-flow/03-prototypes/alt-1-minimalist",
  "note": "What happens if the user declines SSO?",
  "author": "jsmith@acme.com",
  "timestamp": "2026-04-24T14:32:00Z"
}
```

### 6.5 Subagent Critique Memos

Short markdown, no frontmatter, filed as `critiques/<role>.md`. Target 150–400 words. Bullet-point structured. No rambling reasoning dumps. Subagents are prompted explicitly to return a judgment, not a transcript.

### 6.6 User Stories

Plain markdown, conventional template:

```markdown
### Story: <short title>

**As a** <persona from context/personas.md>
**I want** <goal>
**So that** <benefit>

**Acceptance criteria**
- [ ] Observable criterion
- [ ] Observable criterion

**Open questions**
- Question (from TBD or critique)
```

Agent sizes the story count to the prototype's scope. Every TBD in the chosen prototype becomes either a story, an acceptance criterion, or an explicit "out of scope" line.

## 7. The Local Server

### 7.1 Responsibilities

1. Serve static files from a configured root (the ideas repo).
2. Accept `POST /<path>/annotations/<file>.json` and write the body to disk under the configured root. Rejects writes outside the root.
3. Respond to `GET /__ping__` with `200 OK` for client-side detection.

### 7.2 Implementation

Go stdlib only, ~50–100 LOC. Binds to `localhost` only — not a network service. Never accepts writes to paths containing `..` or absolute paths. Configurable port (default 4788) and root (default cwd).

### 7.3 Distribution

Cross-compiled per-platform and shipped in release zips:

- `proto-maker-server-windows-amd64.exe`
- `proto-maker-server-darwin-arm64`
- `proto-maker-server-darwin-amd64`
- `proto-maker-server-linux-amd64`

### 7.4 Signing (v1)

**Unsigned.** README documents SmartScreen and Gatekeeper workarounds with screenshots. Signing (Authenticode on Windows, Apple notarization on macOS) is deferred to v1.1 when adoption justifies the cost and ownership.

## 8. Installation

### 8.1 Distribution Model

User-scoped install. One copy per machine, usable across any number of ideas repos. Upgrades overwrite the install target by re-running the installer with a newer release zip.

### 8.2 Install Locations

**Windows (`install.ps1`):**

- Binary: `%USERPROFILE%\proto-maker\bin\proto-maker-server.exe`
- Skills & agents: wherever Codex CLI's user-scoped skills directory resolves (e.g., `%USERPROFILE%\.codex\skills\proto-maker\`)
- Templates: `%USERPROFILE%\proto-maker\templates\`
- Adds `%USERPROFILE%\proto-maker\bin\` to user PATH
- Runs `Unblock-File` on the binary to clear Mark-of-the-Web

**macOS/Linux (`install.sh`):**

- Binary: `~/.local/bin/proto-maker-server`
- Skills & agents: Codex CLI's user-scoped skills directory (e.g., `~/.codex/skills/proto-maker/`)
- Templates: `~/.proto-maker/templates/`
- Ensures `~/.local/bin/` is on PATH (prints instructions if not)

### 8.3 No Git Assumption

PMs do not need git, GitHub accounts, developer accounts, or any package manager. The installer downloads a release zip via `curl` (or PowerShell's `Invoke-WebRequest`), extracts, and places files. Upgrades are manual by re-downloading and re-running the installer.

Skills must never instruct the PM to run `git`, `gh`, `npm`, `pip`, or any other developer tooling. This is enforced as a constitution rule in `AGENTS.md`.

## 9. Error Handling

| Scenario | Handling |
|---|---|
| `$explore` run before `$setup` (empty/missing context/) | Refuse; direct to `$setup` |
| Later stage run without its required input | Refuse; print expected path and prior stage skill name |
| Critic verdict = `kill` but PM wants to proceed | `$document-scope` prints verdict, requires explicit override, records override in `02-scope.md` |
| Subagent returns empty/incoherent output | Retry once; if still bad, write `critiques/<role>-FAILED.md` and continue |
| Port 4788 in use | `$preview` walks to next available, reports actual URL |
| `proto-maker-server` binary missing from PATH | `$preview` prints reinstall instructions |
| PM re-runs a completed stage | Warn; ask to overwrite or create `.v2` sibling |
| Malformed annotation JSON | `$review-prototypes` lists unreadable files, doesn't fail the stage |
| Every alternative's verdict is `kill` | `$refine` records explicitly; master skill routes back to `$explore` |
| Mid-run abandonment | No cleanup needed; files are the state |
| Stage 6/7/8 run with missing or `none` CHOSEN | Refuse; direct PM to run `$review-prototypes` first (or re-run `$refine` if none were acceptable) |

**Known limitations (README):** single-user per idea; prototypes >30 screens not optimized; no simulated backend data.

## 10. Testing & Verification

### 10.1 End-to-End Dogfood

Canned sample idea: *"Add a dark mode toggle to the settings page."* Run all 8 stages through proto-maker on a Windows VM with Codex CLI. Verify each artifact against its quality bar. This exercise is also the source of the worked example shipped in v1.1.

### 10.2 Per-Stage Contract Tests

`tests/contracts.sh`. For each stage, given a fixture input, confirm the skill's output has:

- Required YAML frontmatter keys
- Required H2 section headings
- Required pointer files (`CHOSEN`, etc.) for downstream gating

Does not evaluate content quality — only structural contracts.

### 10.3 Server Smoke Test

`tests/server-smoke.sh`. Starts binary; asserts:

- `GET /__ping__` → 200
- `POST /test/annotations/sample.json` with valid body → 201 and file on disk
- `POST` with `..` in path → 400
- `POST` outside root → 400

Runs on CI for all three platforms.

### 10.4 Platform Install Verification

Manual per-release checklist:

- **Windows:** unzip → right-click `install.ps1` → "Run with PowerShell". Verify binary on PATH, skills discovered by Codex CLI, SmartScreen prompt documented with screenshot.
- **macOS/Linux:** unzip → `bash install.sh`. Verify binary on PATH, skills discovered.

### 10.5 Offline Annotation Fallback

Open a prototype from `file://`. Add an annotation via the overlay. Click "Copy notes". Verify clipboard contains valid structured JSON matching the shape in §6.4.

### 10.6 Out of Scope for v1 Testing

- Automated LLM output quality evaluation (dogfood is the proxy)
- Load testing (single-user tool)
- Fuzzing (localhost-bound; not a network service)

## 11. Open Decisions for the Implementation Plan

These are deliberately left for the implementation plan, not prejudged here:

- Exact Codex CLI skills directory location per platform (needs verification against current Codex docs at planning time).
- `AGENTS.md` content and tone — PM-persona framing to be drafted in the plan.
- Exact prompts for Designer / Critic / User Advocate / Engineer — drafted in the plan and tuned during dogfood.
- CI setup for building release artifacts (GitHub Actions matrix).
- Release hosting (GitHub Releases vs. internal web drop) — depends on whether the source repo is public.

## 12. Success Criteria for v1

v1 is shippable when:

1. A PM on a clean Windows 11 machine can install proto-maker from a release zip, run `$setup` + `$proto-maker` on the canned sample idea, and produce a valid `HANDOFF.md` + `handoff.zip` without intervention.
2. The same sample runs through on macOS and Linux without platform-specific errors.
3. A stakeholder can receive the handoff zip, extract it, open the chosen prototype in a browser, annotate it, and return structured annotation JSON to the PM — all without the server and without any install.
4. `DESIGN-LOG.md` for every alternative contains a substantive "what changed and what was ignored" section — not placeholders.
5. The contract tests, server smoke tests, and offline fallback test all pass.
