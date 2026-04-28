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
