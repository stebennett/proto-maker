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
echo 'Done. Open Codex CLI and try: $setup'
