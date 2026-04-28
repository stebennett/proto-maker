#!/usr/bin/env bash
#
# Cross-compiles proto-maker-server for all supported platforms.
# Usage: scripts/build-release.sh [VERSION]
#
# Outputs: dist/proto-maker-server-<os>-<arch>[.exe]
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

for target in "${TARGETS[@]}"; do
  goos="${target%/*}"
  goarch="${target#*/}"
  ext=""
  if [ "$goos" = "windows" ]; then
    ext=".exe"
  fi
  bin="proto-maker-server-${goos}-${goarch}${ext}"
  echo "Building $bin (version=$VERSION)..."
  (cd server && GOOS="$goos" GOARCH="$goarch" go build \
      -trimpath \
      -ldflags "-s -w -X main.version=$VERSION" \
      -o "../$OUT/$bin" \
      .)
done

echo ""
echo "Built artifacts:"
ls -lh "$OUT/"
