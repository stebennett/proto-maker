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

# Convert to absolute path so subshells can reference it reliably
ZIP="$PWD/$ZIP"

# 3. Extract to a sandbox, run install with SANDBOX_HOME
echo "=== Step 2: Install into sandbox HOME ==="
SANDBOX=$(mktemp -d)
EXTRACT="$SANDBOX/extract"
mkdir -p "$EXTRACT"
(cd "$EXTRACT" && unzip -q "$ZIP")

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
trap 'kill $SERVER_PID 2>/dev/null; rm -rf "$SANDBOX"' EXIT
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
