#!/usr/bin/env bash
#
# End-to-end smoke test for a built proto-maker-server binary.
# Usage: tests/server-smoke.sh <path-to-binary>
#
set -euo pipefail

BIN="${1:-}"
if [ -z "$BIN" ] || [ ! -x "$BIN" ]; then
  echo "usage: $0 <path-to-proto-maker-server-binary>" >&2
  exit 2
fi

PORT="${SMOKE_PORT:-4798}"
ROOT="$(mktemp -d)"

cleanup() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$ROOT"
}
trap cleanup EXIT

echo "Starting $BIN on port $PORT, root=$ROOT"
"$BIN" --port "$PORT" --root "$ROOT" &
SERVER_PID=$!

# Wait for the server to accept connections (up to 2 seconds).
for i in 1 2 3 4 5 6 7 8 9 10; do
  if curl -sf "http://127.0.0.1:$PORT/__ping__" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

pass=0
fail=0
assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $label"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label — expected $expected, got $actual"
    fail=$((fail + 1))
  fi
}

echo ""
echo "1. GET /__ping__ returns 200"
code=$(curl -sfo /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/__ping__" || echo 000)
assert_eq "ping status" "200" "$code"

echo ""
echo "2. POST valid annotation returns 201 and writes file"
mkdir -p "$ROOT/ideas/sample/03-prototypes/alt-1/annotations"
code=$(curl -so /dev/null -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d '{"note":"hi"}' \
  "http://127.0.0.1:$PORT/ideas/sample/03-prototypes/alt-1/annotations/note-1.json")
assert_eq "annotation POST status" "201" "$code"
if [ -f "$ROOT/ideas/sample/03-prototypes/alt-1/annotations/note-1.json" ]; then
  echo "  PASS: annotation file written to disk"
  pass=$((pass + 1))
else
  echo "  FAIL: annotation file missing from disk"
  fail=$((fail + 1))
fi

echo ""
echo "3. POST with .. traversal returns 400"
code=$(curl --path-as-is -so /dev/null -w "%{http_code}" -X POST \
  -d '{}' \
  "http://127.0.0.1:$PORT/ideas/../outside/annotations/bad.json")
assert_eq "traversal rejected" "400" "$code"

echo ""
echo "4. POST outside annotations/ returns 400"
code=$(curl -so /dev/null -w "%{http_code}" -X POST \
  -d '{}' \
  "http://127.0.0.1:$PORT/ideas/sample/random.json")
assert_eq "non-annotations POST rejected" "400" "$code"

echo ""
echo "5. GET unknown path returns 404"
code=$(curl -so /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/does-not-exist")
assert_eq "missing file 404" "404" "$code"

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" = "0" ]
