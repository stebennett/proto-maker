# proto-maker

Turn a PM's raw idea into an engineering-ready handoff. Ships as a set of open-format skills, agents, templates, and a tiny local server.

- **For PMs:** a Codex CLI-driven pipeline with eight stages: explore → refine → scope → build three wireframe prototypes → review → iterate → user stories → handoff package.
- **For engineering:** a consistent handoff bundle with hypothesis, success criteria, clickable prototype, and conventional user stories with open questions flagged.

## Install

### Windows

1. Download `proto-maker-<version>-windows-amd64.zip` from the releases page.
2. Right-click the zip → "Extract All".
3. Open the extracted folder.
4. Right-click `install.ps1` → "Run with PowerShell".
5. **If you see a "Windows protected your PC" SmartScreen dialog:**
   - Click **More info**.
   - Click **Run anyway**.
   - This is expected — proto-maker is unsigned in v1. See [Signing note](#signing-note-v1).
6. Restart your terminal.
7. Open Codex CLI and type `$setup`.

### macOS

1. Download `proto-maker-<version>-darwin-arm64.zip` (Apple Silicon) or `-darwin-amd64.zip` (Intel).
2. Double-click to extract.
3. Open Terminal in the extracted folder.
4. Run: `bash install.sh`
5. **If macOS blocks the binary with "cannot be opened because the developer cannot be verified":**
   - Open System Settings → Privacy & Security.
   - Scroll down; click **Allow Anyway** next to `proto-maker-server`.
   - Alternative: run `xattr -d com.apple.quarantine ~/.local/bin/proto-maker-server` once.
6. Ensure `~/.local/bin` is on your PATH (the installer prints instructions if not).
7. Open Codex CLI and type `$setup`.

### Linux

1. Download `proto-maker-<version>-linux-amd64.zip`.
2. Extract: `unzip proto-maker-*-linux-amd64.zip`
3. Run: `bash install.sh`
4. Ensure `~/.local/bin` is on your PATH.
5. Open Codex CLI and type `$setup`.

## Quick start

After install:

```
$setup        # one-time: populate your product context (run once per product)
$proto-maker  # start a new idea, walks you through stages 1-8
```

At any point, you can jump to an individual stage: `$explore`, `$refine`, `$document-scope`, `$build-prototypes`, `$review-prototypes`, `$iterate-prototype`, `$write-user-stories`, `$handoff`. Stage skills refuse to run without their required inputs, so you can't get out of order.

To preview prototypes in a browser:

```
$preview      # starts the local server on http://127.0.0.1:4788
```

## What you produce

For each idea, proto-maker creates an `ideas/<slug>/` folder containing:

- `00-exploration.md` — the idea's purpose, who it serves, smallest/biggest versions
- `01-alternatives.md` — three candidate angles, with critic verdict
- `02-scope.md` — hypothesis, success criteria, main risk
- `03-prototypes/alt-*/` — clickable wireframes (three by default)
- `04-review-notes.md` — feedback + winner selection
- `06-user-stories.md` — stories in a conventional template
- `HANDOFF.md` + `handoff.zip` — everything engineering needs

## Known limitations (v1)

- Windows primary; macOS and Linux supported with lighter testing.
- Unsigned binaries — expect SmartScreen / Gatekeeper prompts on first run.
- Single PM per idea (no collaboration).
- Prototypes larger than ~30 screens not optimized.
- No simulated backend data — wireframes only.

## Signing note (v1)

We ship unsigned binaries in v1. This is a deliberate choice to keep distribution friction low during internal rollout. Code signing (Authenticode on Windows, Apple Notarization on macOS) is on the v1.1 roadmap once adoption justifies the ongoing cost.

## Uninstall

### Unix

```bash
rm -f ~/.local/bin/proto-maker-server
rm -rf ~/.codex/skills/proto-maker
rm -rf ~/.proto-maker
# Leave ~/.codex/AGENTS.md alone — it may contain your own rules.
```

### Windows

```powershell
Remove-Item "$env:USERPROFILE\proto-maker" -Recurse -Force
Remove-Item "$env:USERPROFILE\.codex\skills\proto-maker" -Recurse -Force
# Remove the PATH entry manually via System Properties → Environment Variables.
```

---

## For contributors

### Repo layout

```
server/          Go microserver — static files + annotation POSTs
templates/       Wireframe base template (Pico.css + annotations.js) + sample demo
skills/          Codex CLI skills for all 8 pipeline stages
agents/          Four role-specialized subagents (designer, critic, user-advocate, engineer)
scripts/         build-release.sh — cross-compile + package per-platform zips
tests/           server-smoke.sh, contracts.sh, install-verify.sh, wireframe-test.html
docs/            DECISIONS.md, RESUMING.md, superpowers/specs/, superpowers/plans/
TODOS.md         Execution tracker — pick the next unchecked task
CLAUDE.md        Instructions for any agent session in this repo
AGENTS.md        Constitution for skills/agents running on PM machines
```

### Build status

| Phase | Plan | Status |
|---|---|---|
| 1 | Go microserver | ✅ complete |
| 2 | Wireframe template (Pico.css + annotations.js) | ✅ complete |
| 3 | Skills & agents (8 stage skills + 4 subagents) | ✅ complete |
| 4 | Installer & release (CI, zips, install scripts) | ✅ complete |

### Dev commands

```bash
# Go unit + integration tests
(cd server && go test ./...)

# Build release artifacts (4 platform binaries + zips)
bash scripts/build-release.sh 0.1.0

# Server end-to-end smoke (against a built binary)
bash tests/server-smoke.sh dist/proto-maker-server-$(go env GOOS)-$(go env GOARCH)

# Artifact contract tests
bash tests/contracts.sh

# End-to-end install verification (sandbox HOME)
bash tests/install-verify.sh
```

### Architecture summary

- **Codex CLI** is the primary runtime; Claude Code support is deferred to v1.1.
- **PMs have no developer tooling** (no git, npm, pip, gh). Skills and installers must not assume any.
- Four role-specialized subagents (Designer / Critic / User Advocate / Engineer) provide creative tension at refinement and prototype-build stages.
- Wireframes use clean-minimal styling (Pico.css), not sketch/Balsamiq.
- Go static binaries, unsigned in v1.

Full rationale in [docs/DECISIONS.md](docs/DECISIONS.md). Design spec in [docs/superpowers/specs/](docs/superpowers/specs/). Implementation plans in [docs/superpowers/plans/](docs/superpowers/plans/).

Read [CLAUDE.md](CLAUDE.md) before starting any development session — it covers the maintainer/PM context split, load-bearing constraints, and how to pick the next task.
