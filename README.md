# proto-maker

Turn a PM's raw idea into an engineering-ready handoff. Ships as a set of open-format skills, agents, templates, and a tiny local server that walks a Product Manager through an 8-stage pipeline (explore → refine → scope → build three wireframe prototypes → review → iterate → user stories → handoff).

> **Status:** in development. The PM-facing install/usage docs land with the v0.1.0 release (Plan 4, Task 5). For now this README is a skeleton for contributors.

## Repo layout

```
server/                          Go microserver — static files + annotation POSTs (Phase 1 ✅)
scripts/build-release.sh         Cross-compile to 4 platforms
tests/server-smoke.sh            End-to-end smoke test against a built binary
docs/
  DECISIONS.md                   12 load-bearing decisions with rationale
  RESUMING.md                    "I just landed here, now what?" guide
  superpowers/
    specs/                       v1 design spec
    plans/                       4 implementation plans (server, template, skills, installer)
TODOS.md                         Execution tracker — pick the next unchecked task
CLAUDE.md                        Instructions for any agent session in this repo
```

## Build status

| Phase | Plan | Status |
|---|---|---|
| 1 | Go microserver | ✅ complete |
| 2 | Wireframe template (Pico.css + annotations.js) | ✅ complete |
| 3 | Skills & agents (8 stage skills + 4 subagents) | ⏳ not started |
| 4 | Installer & release (CI, zips, install scripts) | ⏳ not started |

See [TODOS.md](TODOS.md) for task-level progress.

## Development

```bash
# Go unit + integration tests
(cd server && go test ./...)

# Cross-compile all 4 platform binaries to dist/
bash scripts/build-release.sh 0.1.0

# End-to-end smoke against a built binary
bash tests/server-smoke.sh dist/proto-maker-server-$(go env GOOS)-$(go env GOARCH)
```

The `server/` subsystem has its own [README](server/README.md) covering endpoints, flags, and security model.

## Architecture at a glance

- **Codex CLI** is the primary runtime; Claude Code support is deferred to v1.1.
- **PMs have no developer tooling** (no git, npm, pip, gh). Skills and installers must not assume any.
- Four role-specialized subagents (Designer / Critic / User Advocate / Engineer) provide creative tension at refinement and prototype-build stages.
- Wireframes use clean-minimal styling (Pico.css), not sketch/Balsamiq.
- Go static binaries, unsigned in v1.

Full rationale in [docs/DECISIONS.md](docs/DECISIONS.md).

## Contributing

Read [CLAUDE.md](CLAUDE.md) first — it covers the maintainer/PM context split, load-bearing constraints, and how to pick the next task.
