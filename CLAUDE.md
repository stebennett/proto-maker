# CLAUDE.md — proto-maker

Instructions for any Claude Code (or Codex / other-agent) session working in THIS repo.

## What this repo is

proto-maker: a portable set of Codex CLI skills + subagents + a tiny Go microserver that walks a Product Manager through an 8-stage pipeline from raw idea to engineering handoff. See [README.md](README.md) (once Plan 4 Task 5 runs) for the PM-facing overview and [docs/superpowers/README.md](docs/superpowers/README.md) for the doc index.

**This is the maintainer repo.** You (Claude) are a developer here. PMs never see this repo — they install release zips built from it.

## Where to start (any session)

1. **[TODOS.md](TODOS.md)** — the execution tracker. Pick the next unchecked task.
2. **[docs/RESUMING.md](docs/RESUMING.md)** — the "I just landed here, now what?" guide.
3. **[docs/DECISIONS.md](docs/DECISIONS.md)** — 12 key decisions with rationale and "do-not-reopen" guidance. **Read before questioning any architectural choice.**
4. **[docs/superpowers/specs/2026-04-24-proto-maker-design.md](docs/superpowers/specs/2026-04-24-proto-maker-design.md)** — the full v1 design spec.
5. **[docs/superpowers/plans/](docs/superpowers/plans/)** — four implementation plans (Server, Template, Skills, Installer) with TDD-structured tasks.

## Two distinct contexts, two distinct rulesets

| Context | Rules |
|---|---|
| **You developing proto-maker** (this repo) | Normal developer workflow: git, Go, shell scripts, GitHub Actions. Use them freely. |
| **Skills / agents / installers inside proto-maker** (the artifacts we produce) | MUST NOT assume dev tooling on PM machines. No git, npm, pip, gh, docker, etc. AGENTS.md enforces this. |

**Do not confuse the two.** You can (and should) use git in this repo. The skills you write in `skills/*/SKILL.md` must not.

## Load-bearing constraints (from DECISIONS.md)

Don't silently reverse these. If a change seems to require one, raise it with the user first:

- **D1:** Codex CLI is the primary runtime; Claude Code is deferred to v1.1.
- **D2:** PMs have no developer tooling. Everything ships in release zips.
- **D4:** Four role-specialized subagents (Designer / Critic / User Advocate / Engineer). Don't collapse them.
- **D5:** `context/*.md` is required before any per-idea skill runs.
- **D6:** Wireframes use clean-minimal styling (Pico.css), not sketch/Balsamiq.
- **D9:** Creative tension lives at BOTH `/refine` and `/build-prototypes`.
- **D10:** Go static binaries, unsigned for v1.

Full rationale for each in [docs/DECISIONS.md](docs/DECISIONS.md).

## How to work

### Picking a task
- Plans 1 and 2 can run in parallel. Plan 3 depends on both. Plan 4 depends on 1+2+3.
- Within a plan, tasks run in order. Each task has 3–6 bite-sized steps with TDD where applicable.

### Executing a task
- Follow the plan step by step. Every code block is complete — don't improvise or abbreviate.
- Commit at the commit step. Use the exact commit message in the plan where given.
- When a task completes: check its box in TODOS.md and commit that change.

### Phase boundaries
Per the user's global instruction: at the end of each phase (= one plan complete), re-read TODOS.md for that phase, verify every sub-task is checked, and if everything is done, update the README if it's in scope.

### When stuck
- If a plan step doesn't work as written, STOP. Don't paper over it — the plan has a bug. Tell the user and propose a fix before continuing.
- If you find yourself wanting to add an unplanned feature, it's probably out of scope. Re-check TODOS.md and the relevant plan.

## What NOT to do

- Don't create new top-level docs without user approval. The doc set is stable: README.md (PM-facing), CLAUDE.md (this file), TODOS.md, docs/DECISIONS.md, docs/RESUMING.md, docs/superpowers/README.md, docs/superpowers/specs/*, docs/superpowers/plans/*.
- Don't commit to `main` without completing the whole task's step sequence. One commit per task step as specified in the plan.
- Don't skip tests. Every plan's tasks include TDD / smoke / contract tests for a reason.
- Don't instruct the user to run `git`, `gh`, or any developer command themselves — you run them via Bash.
- Don't edit the spec or DECISIONS.md silently. Changes to those need user sign-off.

## Testing commands

```bash
# Go unit + integration tests
(cd server && go test ./...)

# Build release artifacts (4 platform binaries + zips)
bash scripts/build-release.sh <version>

# Server end-to-end smoke (against a built binary)
bash tests/server-smoke.sh dist/proto-maker-server-$(go env GOOS)-$(go env GOARCH)

# Artifact contract validation
bash tests/contracts.sh

# Install sandbox test (full release → install → verify)
bash tests/install-verify.sh

# Browser JS test harness (open in a real browser)
open tests/wireframe-test.html  # macOS
xdg-open tests/wireframe-test.html  # Linux
```

Each plan lists which of these to run when.

## Branch / git hygiene

- Work directly on `main`. The repo is greenfield and small; branch overhead isn't justified.
- Commits are conventional-ish: `<subsystem>: <summary>` (e.g., `server: implement ping handler`, `skills: /refine stage 2 dispatch logic`).
- Never force-push. Never `git reset --hard` without user approval.
