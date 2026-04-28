# Proto-maker dogfood walkthrough

This is the canonical end-to-end test for proto-maker. It exercises every
skill, every subagent, and produces a complete handoff package.

The canned idea is intentionally small: **"Add a dark mode toggle to the
settings page."**

## Prerequisites

- Plan 1 complete (proto-maker-server binary built or installed)
- Plan 2 complete (wireframe template files exist)
- Plan 3 complete (this plan — skills and agents installed)
- Plan 4 complete (proto-maker installed via the installer; skills discoverable
  by Codex CLI; `proto-maker-server` on PATH)

## Setup

1. Create a fresh ideas repo:
   ```bash
   mkdir -p ~/scratch/dogfood-ideas
   cd ~/scratch/dogfood-ideas
   ```
2. Open Codex CLI in this directory.

## Walkthrough

### Step 1: `/setup`

Run `/setup`. Walk the three interviews. Use this canned content:

- **Product:** "Acme Cloud", a SaaS analytics dashboard. Top features:
  dashboards, scheduled reports, user permissions.
- **Personas:**
  - "Analytics Lead" — runs the team, customizes dashboards, frustrated by
    cluttered UI in long sessions.
  - "Casual Viewer" — checks dashboards weekly, frustrated by glare in
    evening hours.
- **Constraints:**
  - Technical: must work in Chrome, Edge, Safari (latest 2 versions). No new
    JS dependencies.
  - Brand: must use Acme blue (#0050b3) for primary actions.
  - Operational: must persist user preference across sessions.

Verify `context/product.md`, `context/personas.md`, `context/constraints.md`
were written.

### Step 2: `/proto-maker`

Run `/proto-maker`. Choose "new idea". When asked for the idea, say:
"Add a dark mode toggle to the settings page."

### Step 3: stage 1 (`/explore`)

Walk the exploration interview. Use canned answers:
- Problem: Users in long sessions get eye strain; viewers in low-light hate
  the bright UI.
- Whose problem: Both personas.
- Today's workaround: Browser extensions / OS-level dark mode.
- Trigger: 3 support tickets this quarter.
- Smallest version: A single toggle in settings.
- Ambitious version: Auto-switch by time of day, plus per-dashboard override.
- Out of scope: Print/export theming.

Verify `ideas/add-a-dark-mode-toggle-to-the-settings-page/00-exploration.md`
exists with all 8 H2 sections.

### Step 4: stage 2 (`/refine`)

Let proto-maker propose alternatives. Expect ~3 (e.g., "manual toggle",
"auto-switch", "scheduled"). Confirm them. Wait for the 3 critic memos to
return. Inspect the verdict — for this idea it should be `proceed`.

Verify `01-alternatives.md` exists with verdict block.

### Step 5: stage 3 (`/document-scope`)

Walk through hypothesis, criteria, risk, personas. Suggested:
- Hypothesis: stakeholders agree manual + persisted dark mode is sufficient
  for v1.
- Criteria: stakeholders don't ask for auto-switch in review.
- Risk: assumption that manual is enough.
- Personas: Analytics Lead, Casual Viewer.

Verify `02-scope.md` has all 4 sections.

### Step 6: stage 4 (`/build-prototypes`)

Accept default 3 alternatives. Provide 3 angles (e.g., "settings-toggle",
"global-header-toggle", "auto-by-time"). Wait for designer + critic + UA +
engineer dispatches (~12 parallel subagent calls).

Verify:
- `03-prototypes/alt-*/index.html` exists for all 3
- Each has `DESIGN-LOG.md` with all 5 H2 sections filled in (not just headings)
- Each has `critiques/critic.md`, `critiques/user-advocate.md`,
  `critiques/engineer.md` in 150–400 word range
- `03-prototypes/index.html` is a landing page

### Step 7: `/preview` and visual review

Run `/preview`. Open the URL it prints in a browser. Click through each
alternative. Add a few annotations via the `?` button. Verify they're
written under `03-prototypes/<alt>/annotations/*.json`.

### Step 8: stage 5 (`/review-prototypes`)

Walk the review for each alternative. Pick a winner (e.g., "settings-toggle").

Verify:
- `04-review-notes.md` exists with sections per alternative + Decision
- `03-prototypes/CHOSEN` contains the chosen alt's folder name

### Step 9: stage 6 (`/iterate-prototype`) — optional

Try one iteration. Suggest: "Add a 'reset to system default' button."
Verify `.history/iter-1/` snapshot was made. Verify the chosen alt's HTML
was updated.

### Step 10: stage 7 (`/write-user-stories`)

For each TBD found, classify as story / AC / out-of-scope. Verify
`06-user-stories.md` has frontmatter + In-scope + Out-of-scope sections.
Each story should follow the conventional template.

### Step 11: stage 8 (`/handoff`)

Verify:
- `HANDOFF.md` exists with all required sections populated (no placeholder text)
- `handoff.zip` exists, is non-empty
- Extract `handoff.zip` to a temp dir and confirm
  `03-prototypes/<chosen>/index.html` opens cleanly

### Step 12: contract tests

Run from the proto-maker source repo:
```bash
bash tests/contracts.sh ~/scratch/dogfood-ideas/ideas/add-a-dark-mode-toggle-to-the-settings-page
```

Expected: all assertions pass.

## Pass criteria

- All 11 walkthrough stages complete without proto-maker refusing or erroring
- All artifact contracts pass (`contracts.sh` returns 0)
- The `HANDOFF.md` reads like a real engineering handoff, not placeholder text
- All `DESIGN-LOG.md` files have substantive "Changes made" and "NOT addressed" sections
