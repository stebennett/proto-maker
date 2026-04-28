# proto-maker — Execution Tracker

Follow your global CLAUDE.md rule: check off completed items at the end of each phase. A "phase" here is one plan.

**Dependency order:** Plans 1 and 2 run in parallel → Plan 3 → Plan 4.

**Spec:** `docs/superpowers/specs/2026-04-24-proto-maker-design.md`
**Full plans:** `docs/superpowers/plans/2026-04-24-proto-maker-*.md`
**Quick resume guide:** `docs/RESUMING.md`

---

## Phase 1 — Go Microserver (Plan 1)

Plan: `docs/superpowers/plans/2026-04-24-proto-maker-server.md`

- [x] Task 1: Initialize Go module and skeleton
- [x] Task 2: Write failing tests for path validation
- [x] Task 3: Implement path validation
- [x] Task 4: Write failing tests for HTTP handlers
- [x] Task 5: Implement HTTP handlers
- [x] Task 6: Add outside-root rejection test
- [x] Task 7: Cross-compile script
- [x] Task 8: Server smoke test script
- [x] Task 9: Document the server package
- [x] Task 10: Final verification

**Phase 1 complete when:** all Go tests pass; all 4 binaries cross-compile; smoke test returns 5 PASS, 0 FAIL on the host.

---

## Phase 2 — Wireframe Template (Plan 2)

Plan: `docs/superpowers/plans/2026-04-24-proto-maker-template.md`

- [x] Task 1: Vendor Pico.css
- [x] Task 2: Write components.css
- [x] Task 3: Write the screen template
- [x] Task 4: Write the JS test harness skeleton
- [x] Task 5: Implement annotations.js — mode detection
- [x] Task 6: Implement annotations.js — adding notes (online + offline)
- [x] Task 7: Implement annotations.js — copy-to-clipboard export
- [x] Task 8: Implement annotations.js — overlay UI (button + panel)
- [x] Task 9: Build a sample 3-screen demo prototype
- [x] Task 10: Manual visual verification

**Phase 2 complete when:** all 10 JS assertions pass in the browser harness; sample demo navigates correctly; annotations save online AND offline; clipboard JSON is valid.

---

## Phase 3 — Skills & Agents (Plan 3)

Plan: `docs/superpowers/plans/2026-04-24-proto-maker-skills.md`

- [x] Task 1: AGENTS.md constitution
- [x] Task 2: Designer subagent
- [x] Task 3: Critic subagent
- [x] Task 4: User Advocate subagent
- [x] Task 5: Engineer subagent
- [x] Task 6: /setup skill
- [x] Task 7: /preview skill
- [x] Task 8: /explore skill (stage 1)
- [x] Task 9: /refine skill (stage 2)
- [x] Task 10: /document-scope skill (stage 3)
- [x] Task 11: /build-prototypes skill (stage 4)
- [x] Task 12: /review-prototypes skill (stage 5)
- [x] Task 13: /iterate-prototype skill (stage 6)
- [x] Task 14: /write-user-stories skill (stage 7)
- [x] Task 15: /handoff skill (stage 8)
- [x] Task 16: /proto-maker master skill
- [x] Task 17: Contract test infrastructure
- [x] Task 18: Dogfood walkthrough doc

**Phase 3 complete when:** every markdown artifact exists with required frontmatter and structure; `tests/contracts.sh` passes against the fixture; the dogfood walkthrough doc is ready for a real run (the actual dogfood happens as part of Plan 4 verification).

---

## Phase 4 — Installer & Release (Plan 4)

Plan: `docs/superpowers/plans/2026-04-24-proto-maker-installer.md`

- [x] Task 1: install.sh (macOS/Linux)
- [x] Task 2: install.ps1 (Windows)
- [x] Task 3: Extend build-release.sh to produce per-platform zips
- [x] Task 4: Local install verification
- [x] Task 5: Repo-level README.md
- [x] Task 6: GitHub Actions release workflow
- [x] Task 7: Final end-to-end verification

**Phase 4 complete when:** `tests/install-verify.sh` passes; a release zip, when extracted and installed into a sandbox HOME, places files in the expected locations and the installed binary responds to `/__ping__`.

---

## v1 Ship Gate

v1 is shippable when:

- [x] All four phases complete (checkboxes above)
- [ ] Dogfood walkthrough (Plan 3, Task 18) succeeds end-to-end on a Windows VM against an installed release zip
- [ ] A GitHub Release tagged `v0.1.0` has all four platform zips attached (or equivalent internal hosting)
- [ ] README.md screenshots of SmartScreen/Gatekeeper workarounds added (TBD by maintainer — Plan 4 README has text-only)

Spec success criteria live in `docs/superpowers/specs/2026-04-24-proto-maker-design.md` §12.
