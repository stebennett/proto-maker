# Proto-Maker Installer & Release Tooling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package everything from Plans 1–3 into per-platform release zips, ship `install.sh` (macOS/Linux) and `install.ps1` (Windows) installers that work without git/developer tooling on the PM's machine, and wire up CI to produce reproducible release artifacts.

**Architecture:** `scripts/build-release.sh` cross-compiles the Go server (reusing Plan 1's infrastructure), then zips a per-platform bundle containing the binary, skills/, agents/, templates/, installer script, and README. Installers place files in well-known user-scoped locations: binary in `~/.local/bin/` (Unix) or `%USERPROFILE%\proto-maker\bin\` (Windows); skills/agents in `~/.codex/skills/proto-maker/` (Unix) or `%USERPROFILE%\.codex\skills\proto-maker\` (Windows); templates in `~/.proto-maker/templates/` (Unix) or `%USERPROFILE%\proto-maker\templates\` (Windows).

**Tech Stack:** bash, PowerShell, Go (already in use for the server), GitHub Actions YAML.

**Depends on:** Plans 1, 2, and 3 complete.

---

## Scope

**This plan delivers:**
- `install.sh` (macOS + Linux)
- `install.ps1` (Windows)
- Extended `scripts/build-release.sh` that bundles release zips
- `tests/install-verify.sh` — exercises install.sh into a temporary HOME, asserts file placement
- `README.md` — install instructions, quick-start, SmartScreen/Gatekeeper workarounds
- `.github/workflows/release.yml` — CI that builds, tests, and uploads release artifacts

**This plan does NOT deliver:**
- Code signing (explicitly deferred to v1.1 per spec §7.4)
- Windows / Linux runtime install verification (requires target machines)
- Release hosting decision (spec §11 open item)

**End state of this plan:** On a clean macOS dev machine, a developer can run `bash scripts/build-release.sh 0.1.0`, then `bash tests/install-verify.sh` and see a full install + contract-test pass. The `.github/workflows/release.yml` is wired so pushing a git tag `v0.1.0` produces per-platform release zips attached to a GitHub release.

---

## File Structure

```
install.sh                             # macOS/Linux installer
install.ps1                            # Windows installer
scripts/
  build-release.sh                     # extended: now produces per-platform zips
tests/
  install-verify.sh                    # runs install.sh into a sandbox HOME
  contracts.sh                         # (from Plan 3) re-used for post-install verification
README.md                              # repo-level README: install, quick-start, workarounds
.github/
  workflows/
    release.yml                        # CI: tag v* → cross-compile → test → release
```

**Boundaries:**
- Installers must be self-contained: no downloads during install (everything needed is in the release zip).
- Skills must never assume a specific install path — they resolve templates via `$PROTO_MAKER_HOME` or the platform-default location.

---

## Task 1: Write install.sh (macOS/Linux)

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Write the installer**

Write `install.sh`:

```bash
#!/usr/bin/env bash
#
# proto-maker installer (macOS / Linux)
#
# Usage: bash install.sh
#
# Must be run from the extracted release zip directory. Installs:
#   - binary → ~/.local/bin/proto-maker-server
#   - skills → ~/.codex/skills/proto-maker/
#   - agents → ~/.codex/skills/proto-maker/agents/
#   - templates → ~/.proto-maker/templates/
#   - AGENTS.md → ~/.codex/AGENTS.md (if none exists; else prints instruction)
#
set -euo pipefail

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect host architecture for binary selection.
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH=amd64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 2 ;;
esac

case "$OS" in
  darwin|linux) ;;
  *) echo "Unsupported OS: $OS. Use install.ps1 on Windows." >&2; exit 2 ;;
esac

BINARY_SRC="$INSTALL_DIR/proto-maker-server-${OS}-${ARCH}"
if [ ! -x "$BINARY_SRC" ]; then
  echo "Expected binary not found: $BINARY_SRC" >&2
  echo "Make sure you extracted the release zip for your platform." >&2
  exit 2
fi

echo "Installing proto-maker for ${OS}-${ARCH}..."

# Binary → ~/.local/bin
mkdir -p "$HOME/.local/bin"
cp "$BINARY_SRC" "$HOME/.local/bin/proto-maker-server"
chmod +x "$HOME/.local/bin/proto-maker-server"
echo "  Binary installed to $HOME/.local/bin/proto-maker-server"

# Skills + agents → ~/.codex/skills/proto-maker/
SKILLS_DIR="$HOME/.codex/skills/proto-maker"
rm -rf "$SKILLS_DIR"
mkdir -p "$SKILLS_DIR"
cp -R "$INSTALL_DIR/skills/." "$SKILLS_DIR/"
mkdir -p "$SKILLS_DIR/agents"
cp -R "$INSTALL_DIR/agents/." "$SKILLS_DIR/agents/"
echo "  Skills installed to $SKILLS_DIR"

# Templates → ~/.proto-maker/templates
TEMPLATES_DIR="$HOME/.proto-maker/templates"
rm -rf "$TEMPLATES_DIR"
mkdir -p "$TEMPLATES_DIR"
cp -R "$INSTALL_DIR/templates/." "$TEMPLATES_DIR/"
echo "  Templates installed to $TEMPLATES_DIR"

# AGENTS.md — only write if user doesn't already have one in ~/.codex/
AGENTS_TARGET="$HOME/.codex/AGENTS.md"
if [ -f "$AGENTS_TARGET" ]; then
  echo "  NOTE: $AGENTS_TARGET already exists. Not overwriting."
  echo "        Review whether you need to merge proto-maker rules into it."
  echo "        proto-maker's AGENTS.md is at: $INSTALL_DIR/AGENTS.md"
else
  cp "$INSTALL_DIR/AGENTS.md" "$AGENTS_TARGET"
  echo "  AGENTS.md installed to $AGENTS_TARGET"
fi

# PATH check
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *)
    echo ""
    echo "  IMPORTANT: $HOME/.local/bin is not on your PATH."
    echo "  Add this line to your shell config (~/.bashrc or ~/.zshrc):"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "  Then restart your terminal."
    ;;
esac

echo ""
echo "Done. Open Codex CLI and try: /setup"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x install.sh
```

- [ ] **Step 3: Commit**

```bash
git add install.sh
git commit -m "installer: install.sh for macOS and Linux"
```

---

## Task 2: Write install.ps1 (Windows)

**Files:**
- Create: `install.ps1`

- [ ] **Step 1: Write the PowerShell installer**

Write `install.ps1`:

```powershell
# proto-maker installer (Windows)
#
# Usage: Right-click this file → Run with PowerShell
# Or:    PowerShell -ExecutionPolicy Bypass -File install.ps1
#
# Installs:
#   - binary   → %USERPROFILE%\proto-maker\bin\proto-maker-server.exe
#   - skills   → %USERPROFILE%\.codex\skills\proto-maker\
#   - agents   → %USERPROFILE%\.codex\skills\proto-maker\agents\
#   - templates→ %USERPROFILE%\proto-maker\templates\
#   - AGENTS.md→ %USERPROFILE%\.codex\AGENTS.md (if none exists)
#
# Adds %USERPROFILE%\proto-maker\bin\ to the user PATH.
# Runs Unblock-File on the .exe to clear Mark-of-the-Web.

$ErrorActionPreference = "Stop"

$InstallDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserProfile = $env:USERPROFILE

# Detect arch
$Arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else {
    Write-Error "32-bit Windows not supported."; exit 2
}

$BinarySrc = Join-Path $InstallDir "proto-maker-server-windows-$Arch.exe"
if (-not (Test-Path $BinarySrc)) {
    Write-Error "Expected binary not found: $BinarySrc"
    exit 2
}

Write-Host "Installing proto-maker for windows-$Arch..."

# Binary
$BinDir = Join-Path $UserProfile "proto-maker\bin"
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
$BinDest = Join-Path $BinDir "proto-maker-server.exe"
Copy-Item -Force $BinarySrc $BinDest
Unblock-File $BinDest
Write-Host "  Binary installed to $BinDest"

# Skills + agents
$SkillsDir = Join-Path $UserProfile ".codex\skills\proto-maker"
if (Test-Path $SkillsDir) { Remove-Item -Recurse -Force $SkillsDir }
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $InstallDir "skills\*") $SkillsDir
$AgentsDir = Join-Path $SkillsDir "agents"
New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $InstallDir "agents\*") $AgentsDir
Write-Host "  Skills installed to $SkillsDir"

# Templates
$TemplatesDir = Join-Path $UserProfile "proto-maker\templates"
if (Test-Path $TemplatesDir) { Remove-Item -Recurse -Force $TemplatesDir }
New-Item -ItemType Directory -Force -Path $TemplatesDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $InstallDir "templates\*") $TemplatesDir
Write-Host "  Templates installed to $TemplatesDir"

# AGENTS.md
$AgentsMdTarget = Join-Path $UserProfile ".codex\AGENTS.md"
if (Test-Path $AgentsMdTarget) {
    Write-Host "  NOTE: $AgentsMdTarget already exists. Not overwriting."
    Write-Host "        proto-maker's AGENTS.md is at: $(Join-Path $InstallDir 'AGENTS.md')"
} else {
    New-Item -ItemType Directory -Force -Path (Split-Path $AgentsMdTarget) | Out-Null
    Copy-Item -Force (Join-Path $InstallDir "AGENTS.md") $AgentsMdTarget
    Write-Host "  AGENTS.md installed to $AgentsMdTarget"
}

# PATH: add $BinDir to user PATH if not already there
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notlike "*$BinDir*") {
    $NewPath = if ($UserPath) { "$UserPath;$BinDir" } else { $BinDir }
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
    Write-Host "  Added $BinDir to user PATH (restart your terminal for this to take effect)"
} else {
    Write-Host "  $BinDir already on user PATH"
}

Write-Host ""
Write-Host "Done. Open Codex CLI in a new terminal and try: /setup"
Write-Host ""
Write-Host "If Windows SmartScreen blocked this script, see README.md for the bypass."
```

- [ ] **Step 2: Commit**

```bash
git add install.ps1
git commit -m "installer: install.ps1 for Windows (with Unblock-File and user PATH)"
```

---

## Task 3: Extend build-release.sh to produce per-platform zips

**Files:**
- Modify: `scripts/build-release.sh`

- [ ] **Step 1: Replace the script with the packaging-aware version**

Open `scripts/build-release.sh` (created in Plan 1, Task 7). Replace its contents with:

```bash
#!/usr/bin/env bash
#
# Cross-compiles proto-maker-server AND packages per-platform release zips.
# Each zip contains: binary + skills + agents + templates + AGENTS.md + installer + README.
#
# Usage: scripts/build-release.sh [VERSION]
#
# Outputs:
#   dist/proto-maker-server-<os>-<arch>[.exe]   — raw binaries
#   dist/proto-maker-<version>-<os>-<arch>.zip  — installable release zips
#
set -euo pipefail

VERSION="${1:-dev}"
OUT="dist"

cd "$(dirname "$0")/.."

rm -rf "$OUT"
mkdir -p "$OUT"

TARGETS=(
  "windows/amd64"
  "darwin/arm64"
  "darwin/amd64"
  "linux/amd64"
)

echo "=== Cross-compiling binaries ==="
for target in "${TARGETS[@]}"; do
  goos="${target%/*}"
  goarch="${target#*/}"
  ext=""
  [ "$goos" = "windows" ] && ext=".exe"
  bin="proto-maker-server-${goos}-${goarch}${ext}"
  echo "  Building $bin (version=$VERSION)..."
  (cd server && GOOS="$goos" GOARCH="$goarch" go build \
      -trimpath \
      -ldflags "-s -w -X main.version=$VERSION" \
      -o "../$OUT/$bin" \
      .)
done

echo ""
echo "=== Packaging release zips ==="
for target in "${TARGETS[@]}"; do
  goos="${target%/*}"
  goarch="${target#*/}"
  ext=""
  [ "$goos" = "windows" ] && ext=".exe"
  bin="proto-maker-server-${goos}-${goarch}${ext}"

  STAGE="$OUT/stage-${goos}-${goarch}"
  rm -rf "$STAGE"
  mkdir -p "$STAGE"

  # Place the single binary matching the target arch
  cp "$OUT/$bin" "$STAGE/"

  # Common payload
  cp -R skills "$STAGE/"
  cp -R agents "$STAGE/"
  cp -R templates "$STAGE/"
  cp AGENTS.md "$STAGE/"
  cp README.md "$STAGE/" 2>/dev/null || true  # README may not exist until Task 5

  # Platform installer
  if [ "$goos" = "windows" ]; then
    cp install.ps1 "$STAGE/"
  else
    cp install.sh "$STAGE/"
  fi

  # Zip it
  ZIP="$OUT/proto-maker-${VERSION}-${goos}-${goarch}.zip"
  (cd "$STAGE" && zip -qr "../$(basename "$ZIP")" .)
  rm -rf "$STAGE"
  echo "  Packaged $ZIP ($(du -h "$ZIP" | cut -f1))"
done

echo ""
echo "=== Release artifacts ==="
ls -lh "$OUT/"*.zip
```

- [ ] **Step 2: Test it**

```bash
bash scripts/build-release.sh 0.1.0-test
ls -lh dist/
```

Expected: 4 binaries AND 4 zip files visible. Each zip ~5–10MB.

- [ ] **Step 3: Inspect a zip's contents**

```bash
unzip -l dist/proto-maker-0.1.0-test-darwin-arm64.zip
```

Expected: contains `proto-maker-server-darwin-arm64`, `skills/`, `agents/`, `templates/`, `AGENTS.md`, `install.sh`.

- [ ] **Step 4: Clean and commit**

```bash
rm -rf dist
git add scripts/build-release.sh
git commit -m "installer: package per-platform release zips with skills+agents+templates+installer"
```

---

## Task 4: Local install verification

**Files:**
- Create: `tests/install-verify.sh`

- [ ] **Step 1: Write the verification script**

Write `tests/install-verify.sh`:

```bash
#!/usr/bin/env bash
#
# Verifies install.sh places files correctly by installing into a sandbox HOME.
# Does NOT modify the developer's real HOME.
#
# Usage: bash tests/install-verify.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

# 1. Build release artifacts
echo "=== Step 1: Build release ==="
bash scripts/build-release.sh dev-test

# 2. Determine host platform
HOST_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
HOST_ARCH=$(uname -m)
case "$HOST_ARCH" in x86_64|amd64) HOST_ARCH=amd64;; arm64|aarch64) HOST_ARCH=arm64;; esac

ZIP="dist/proto-maker-dev-test-${HOST_OS}-${HOST_ARCH}.zip"
if [ ! -f "$ZIP" ]; then
  echo "No zip for host platform: $ZIP" >&2
  exit 2
fi

# 3. Extract to a sandbox, run install with SANDBOX_HOME
echo "=== Step 2: Install into sandbox HOME ==="
SANDBOX=$(mktemp -d)
EXTRACT="$SANDBOX/extract"
mkdir -p "$EXTRACT"
(cd "$EXTRACT" && unzip -q "../../$ZIP")

HOME="$SANDBOX" bash "$EXTRACT/install.sh"

# 4. Verify placements
echo ""
echo "=== Step 3: Verify file placement ==="
pass=0; fail=0
check() {
  if [ -e "$1" ]; then
    echo "  PASS: $1 present"; pass=$((pass+1))
  else
    echo "  FAIL: $1 missing"; fail=$((fail+1))
  fi
}

check "$SANDBOX/.local/bin/proto-maker-server"
check "$SANDBOX/.codex/skills/proto-maker/proto-maker/SKILL.md"
check "$SANDBOX/.codex/skills/proto-maker/setup/SKILL.md"
check "$SANDBOX/.codex/skills/proto-maker/build-prototypes/SKILL.md"
check "$SANDBOX/.codex/skills/proto-maker/handoff/SKILL.md"
check "$SANDBOX/.codex/skills/proto-maker/agents/designer.md"
check "$SANDBOX/.codex/skills/proto-maker/agents/critic.md"
check "$SANDBOX/.codex/skills/proto-maker/agents/user-advocate.md"
check "$SANDBOX/.codex/skills/proto-maker/agents/engineer.md"
check "$SANDBOX/.proto-maker/templates/wireframe-base/pico.min.css"
check "$SANDBOX/.proto-maker/templates/wireframe-base/annotations.js"
check "$SANDBOX/.codex/AGENTS.md"

# 5. Verify the installed binary runs
echo ""
echo "=== Step 4: Verify binary runs ==="
BIN="$SANDBOX/.local/bin/proto-maker-server"
PORT=4796
"$BIN" --port $PORT --root "$SANDBOX" &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null; rm -rf "$SANDBOX" dist' EXIT
for i in 1 2 3 4 5 6 7 8 9 10; do
  if curl -sf "http://127.0.0.1:$PORT/__ping__" >/dev/null 2>&1; then break; fi
  sleep 0.2
done
if curl -sf "http://127.0.0.1:$PORT/__ping__" >/dev/null; then
  echo "  PASS: installed binary responds to /__ping__"; pass=$((pass+1))
else
  echo "  FAIL: installed binary not responding"; fail=$((fail+1))
fi
kill $SERVER_PID 2>/dev/null || true

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" = "0" ]
```

- [ ] **Step 2: Make executable**

```bash
chmod +x tests/install-verify.sh
```

- [ ] **Step 3: Run it**

```bash
bash tests/install-verify.sh
```

Expected: all PASS lines, exit code 0. The sandbox HOME and dist/ are cleaned up by the trap.

- [ ] **Step 4: Commit**

```bash
git add tests/install-verify.sh
git commit -m "installer: install-verify.sh sandbox integration test"
```

---

## Task 5: Repo-level README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write the README**

Write `README.md`:

```markdown
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
7. Open Codex CLI and type `/setup`.

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
7. Open Codex CLI and type `/setup`.

### Linux

1. Download `proto-maker-<version>-linux-amd64.zip`.
2. Extract: `unzip proto-maker-*-linux-amd64.zip`
3. Run: `bash install.sh`
4. Ensure `~/.local/bin` is on your PATH.
5. Open Codex CLI and type `/setup`.

## Quick start

After install:

```
/setup        # one-time: populate your product context (run once per product)
/proto-maker  # start a new idea, walks you through stages 1-8
```

At any point, you can jump to an individual stage: `/explore`, `/refine`, `/document-scope`, `/build-prototypes`, `/review-prototypes`, `/iterate-prototype`, `/write-user-stories`, `/handoff`. Stage skills refuse to run without their required inputs, so you can't get out of order.

To preview prototypes in a browser:

```
/preview      # starts the local server on http://127.0.0.1:4788
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

## Development

See `docs/superpowers/specs/` for the design spec and `docs/superpowers/plans/` for implementation plans (four sub-plans: server, template, skills, installer).

To build a release locally:

```bash
bash scripts/build-release.sh 0.1.0
```

To run tests:

```bash
(cd server && go test ./...)       # Go unit + integration tests
bash tests/server-smoke.sh dist/proto-maker-server-$(go env GOOS)-$(go env GOARCH)
bash tests/contracts.sh            # artifact contract tests
bash tests/install-verify.sh       # end-to-end install
```

## License

TBD — see your organization's policy.
```

- [ ] **Step 2: Rerun build-release.sh to pick up the README**

```bash
bash scripts/build-release.sh 0.1.0-with-readme
unzip -l dist/proto-maker-0.1.0-with-readme-darwin-arm64.zip | grep README.md
rm -rf dist
```

Expected: README.md appears in the zip listing.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "installer: repo-level README with install + SmartScreen/Gatekeeper workarounds"
```

---

## Task 6: GitHub Actions release workflow

**Files:**
- Create: `.github/workflows/release.yml`

- [ ] **Step 1: Write the workflow**

Write `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - "v*.*.*"
  workflow_dispatch:
    inputs:
      version:
        description: "Version tag (e.g., 0.1.0)"
        required: true

jobs:
  test-unix:
    name: Test on Unix
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.22"
      - name: Go unit tests
        run: cd server && go test ./... -v
      - name: Build release
        run: bash scripts/build-release.sh ${{ github.ref_name }}
      - name: Server smoke test
        run: bash tests/server-smoke.sh dist/proto-maker-server-linux-amd64
      - name: Contract tests
        run: bash tests/contracts.sh
      - name: Install verify
        run: bash tests/install-verify.sh
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: release-zips
          path: dist/*.zip
          retention-days: 7

  release:
    name: Create GitHub Release
    needs: [test-unix]
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: release-zips
          path: dist
      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          files: dist/*.zip
          body: |
            ## proto-maker ${{ github.ref_name }}

            See [README.md](README.md) for install instructions.

            ### Platform zips

            Pick the zip matching your machine:
            - `proto-maker-${{ github.ref_name }}-windows-amd64.zip` — Windows 64-bit
            - `proto-maker-${{ github.ref_name }}-darwin-arm64.zip` — macOS Apple Silicon
            - `proto-maker-${{ github.ref_name }}-darwin-amd64.zip` — macOS Intel
            - `proto-maker-${{ github.ref_name }}-linux-amd64.zip` — Linux 64-bit

            **Note:** Binaries are unsigned in v1. See README.md for SmartScreen / Gatekeeper workarounds.
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "installer: GitHub Actions release workflow — build, test, attach zips"
```

---

## Task 7: Final end-to-end verification

- [ ] **Step 1: Run the full local release + install + test cycle**

```bash
# Build
bash scripts/build-release.sh 0.1.0

# Server smoke test
HOST_OS=$(go env GOOS)
HOST_ARCH=$(go env GOARCH)
bash tests/server-smoke.sh dist/proto-maker-server-${HOST_OS}-${HOST_ARCH}

# Contract tests
bash tests/contracts.sh

# Install verify (includes its own release build)
rm -rf dist
bash tests/install-verify.sh
```

Expected: every step exits 0, all assertions PASS.

- [ ] **Step 2: Confirm the git log tells the complete story**

```bash
git log --oneline
```

Expected (at minimum — the exact subjects will depend on your plan-execution history):

```
installer: GitHub Actions release workflow ...
installer: repo-level README ...
installer: install-verify.sh sandbox integration test
installer: package per-platform release zips ...
installer: install.ps1 for Windows ...
installer: install.sh for macOS and Linux
skills: /proto-maker master orchestrator ...
skills: /handoff ...
... (remaining skills and agents from Plan 3)
template: ... (Plan 2)
server: ... (Plan 1)
Add Plan 4 ...
Add Plan 3 ...
Add Plan 2 ...
Add Plan 1 ...
Add proto-maker v1 design spec
```

- [ ] **Step 3: Tag a release and verify the workflow**

If you're ready to produce a v0.1.0 release:

```bash
git tag v0.1.0
# Inspect and confirm before pushing:
git show v0.1.0 --stat
# To trigger the CI release, push the tag to the remote. (Do NOT push if you're
# not ready — the release workflow will create a public GitHub release.)
# git push origin v0.1.0
```

Optional. Skip this step if you're not hosting on GitHub yet.

- [ ] **Step 4: Done**

proto-maker v1 is shippable when:
1. Every test in every plan passes on the dev host.
2. `tests/install-verify.sh` succeeds.
3. Tagging and pushing `v0.1.0` produces a successful GitHub Actions run with all four zips attached to a release.
4. The dogfood walkthrough (Plan 3, Task 18) succeeds on a Windows VM against the installed release zip.

---

## Spec Coverage Self-Check

| Spec § | Requirement | Task |
|---|---|---|
| §3 | Windows primary, macOS/Linux also supported | Tasks 1, 2, 3, 5 |
| §7.3 | Release-packaged per-platform zips | Task 3 |
| §7.4 | Unsigned in v1, document workarounds | Task 5 (README sections) |
| §8.1 | User-scoped install, one copy per machine | Tasks 1, 2 |
| §8.2 | Install locations per platform | Tasks 1, 2 |
| §8.3 | No git / developer-tooling assumption | Tasks 1, 2 (pure bash/PowerShell, curl not needed since zip is already local), §3 README |
| §10.4 | Install verification per platform | Tasks 4, 7 |

**Gaps intentionally deferred:**
- Signed binaries (v1.1).
- Windows runtime testing on a real Windows machine (requires access to one).
- Release hosting decision beyond "GitHub Releases" (default chosen in CI; alternative internal drop is the org's call).
