# Proto-Maker Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a tiny static-file HTTP server in Go that the `/preview` skill launches on the PM's machine. It serves the ideas repo, accepts annotation POSTs from the wireframe overlay, and cross-compiles to Windows, macOS, and Linux binaries.

**Architecture:** One Go process binding to `127.0.0.1` only. Three endpoints: `GET /__ping__` (liveness probe for the overlay's online/offline detection), `POST /<path>/annotations/*.json` (writes annotation JSON to disk under the configured root), and static file serving for everything else. Path-traversal attempts, absolute paths, and paths escaping the root are rejected before any disk write.

**Tech Stack:** Go 1.22+ (stdlib only — `net/http`, `flag`, `path/filepath`, `os`, `errors`). Tests use `net/http/httptest`. Cross-compilation via `GOOS=… GOARCH=… go build`. Shell scripts for the release build and the smoke test.

---

## Scope

**This plan delivers:**
- `server/` directory with Go source, unit tests, and integration tests
- `scripts/build-release.sh` cross-compile script producing 4 binaries
- `tests/server-smoke.sh` end-to-end smoke test against a running binary
- Binaries verified to start on macOS (dev machine) and cross-compile cleanly for all four targets

**This plan does NOT deliver:**
- Windows/macOS runtime verification (requires target machines — manual checklist in spec §10.4)
- Installer scripts (Plan 4)
- CI setup (Plan 4)
- Release hosting (out of scope — open decision in spec §11)

**End state of this plan:** A developer can run `bash scripts/build-release.sh 0.1.0`, get four binaries in `dist/`, run `bash tests/server-smoke.sh dist/proto-maker-server-darwin-arm64` (substituting the host arch), and see all smoke-test assertions pass.

---

## File Structure

```
server/
  go.mod              # module proto-maker-server (Go 1.22)
  main.go             # entry point: flags, root validation, server start
  handlers.go         # ping, static, annotation-POST HTTP handlers
  paths.go            # ValidateAnnotationPath — the one security-critical function
  paths_test.go       # unit tests for path validation
  main_test.go        # integration tests via httptest
scripts/
  build-release.sh    # cross-compile to 4 targets, zip nothing (packaging is Plan 4)
tests/
  server-smoke.sh     # run a real binary, curl all three endpoints, assert
```

**Boundaries:**
- `paths.go` owns all path-safety logic. It's the blast radius for security bugs; isolating it keeps tests focused.
- `handlers.go` owns HTTP semantics. It's stateless; all state (root path) is passed in at construction.
- `main.go` owns process lifecycle: flag parsing, root validation, server start. Nothing else.

---

## Task 1: Initialize Go module and skeleton

**Files:**
- Create: `server/go.mod`
- Create: `server/main.go`

- [ ] **Step 1: Create the module file**

Write `server/go.mod`:

```
module proto-maker-server

go 1.22
```

- [ ] **Step 2: Create the main.go skeleton**

Write `server/main.go`:

```go
package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
)

func main() {
	port := flag.Int("port", 4788, "port to listen on")
	root := flag.String("root", ".", "document root served to the browser")
	flag.Parse()

	absRoot, err := filepath.Abs(*root)
	if err != nil {
		log.Fatalf("resolve root: %v", err)
	}
	info, err := os.Stat(absRoot)
	if err != nil || !info.IsDir() {
		log.Fatalf("root %q is not a directory", absRoot)
	}

	addr := fmt.Sprintf("127.0.0.1:%d", *port)
	log.Printf("proto-maker-server listening on http://%s (root=%s)", addr, absRoot)
	if err := http.ListenAndServe(addr, newMux(absRoot)); err != nil {
		log.Fatalf("listen: %v", err)
	}
}

// newMux is defined in handlers.go (will be created in a later task).
// For now, a temporary stub lives here so the package compiles.
func newMux(root string) http.Handler {
	return http.NotFoundHandler()
}
```

- [ ] **Step 3: Verify the module builds**

Run: `cd server && go build ./...`
Expected: no output, exit 0. A compiled binary is written to `server/proto-maker-server` (or `.exe` on Windows). Delete it: `rm -f server/proto-maker-server`.

- [ ] **Step 4: Commit**

```bash
git add server/go.mod server/main.go
git commit -m "server: init Go module and main skeleton"
```

---

## Task 2: Write failing tests for path validation

**Files:**
- Create: `server/paths_test.go`

- [ ] **Step 1: Write the failing test**

Write `server/paths_test.go`:

```go
package main

import (
	"errors"
	"path/filepath"
	"strings"
	"testing"
)

func TestValidateAnnotationPath(t *testing.T) {
	root := t.TempDir()

	cases := []struct {
		name    string
		urlPath string
		wantErr error
	}{
		{"simple nested path", "ideas/foo/03-prototypes/alt-1/annotations/note.json", nil},
		{"dot-dot traversal", "ideas/../../etc/passwd", ErrPathTraversal},
		{"dot-dot mid-path", "ideas/foo/../../../../etc/passwd", ErrPathTraversal},
		{"absolute path", "/etc/passwd", ErrPathAbsolute},
		{"empty path", "", ErrPathEmpty},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := ValidateAnnotationPath(root, tc.urlPath)
			if tc.wantErr != nil {
				if !errors.Is(err, tc.wantErr) {
					t.Fatalf("got err %v, want %v", err, tc.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected err: %v", err)
			}
			// Happy path: result must be inside the root.
			rel, relErr := filepath.Rel(root, got)
			if relErr != nil {
				t.Fatalf("rel: %v", relErr)
			}
			if strings.HasPrefix(rel, "..") {
				t.Fatalf("result %q escaped root %q (rel=%q)", got, root, rel)
			}
		})
	}
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd server && go test ./...`
Expected: FAIL with undefined errors — `ValidateAnnotationPath`, `ErrPathTraversal`, `ErrPathAbsolute`, `ErrPathEmpty` are not declared.

---

## Task 3: Implement path validation

**Files:**
- Create: `server/paths.go`

- [ ] **Step 1: Write the implementation**

Write `server/paths.go`:

```go
package main

import (
	"errors"
	"path/filepath"
	"strings"
)

var (
	ErrPathEmpty       = errors.New("path is empty")
	ErrPathAbsolute    = errors.New("path is absolute")
	ErrPathTraversal   = errors.New("path contains traversal segment")
	ErrPathOutsideRoot = errors.New("path escapes configured root")
)

// ValidateAnnotationPath checks that urlPath is a safe, relative path that,
// when joined with root, stays within root. It returns the cleaned absolute
// disk path, or an error describing why the path was rejected.
//
// Rejection rules:
//   - empty path
//   - absolute path (Unix leading /, or Windows drive-letter prefix)
//   - any segment equal to ".." before Clean
//   - after joining with the absolute root, the result must still be within root
func ValidateAnnotationPath(root, urlPath string) (string, error) {
	if urlPath == "" {
		return "", ErrPathEmpty
	}
	if strings.HasPrefix(urlPath, "/") || filepath.IsAbs(urlPath) {
		return "", ErrPathAbsolute
	}
	// Reject traversal by inspecting raw segments before Clean collapses them.
	for _, seg := range strings.Split(urlPath, "/") {
		if seg == ".." {
			return "", ErrPathTraversal
		}
	}

	absRoot, err := filepath.Abs(root)
	if err != nil {
		return "", err
	}
	joined := filepath.Join(absRoot, filepath.FromSlash(urlPath))
	rel, err := filepath.Rel(absRoot, joined)
	if err != nil {
		return "", err
	}
	if rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return "", ErrPathOutsideRoot
	}
	return joined, nil
}
```

- [ ] **Step 2: Run tests to verify pass**

Run: `cd server && go test ./... -run TestValidateAnnotationPath -v`
Expected: all 5 sub-tests PASS.

- [ ] **Step 3: Commit**

```bash
git add server/paths.go server/paths_test.go
git commit -m "server: path validation with traversal rejection"
```

---

## Task 4: Write failing tests for HTTP handlers

**Files:**
- Create: `server/main_test.go`

- [ ] **Step 1: Write the integration test**

Write `server/main_test.go`:

```go
package main

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func newTestServer(t *testing.T) (*httptest.Server, string) {
	t.Helper()
	root := t.TempDir()
	// Seed a static file to serve.
	if err := os.WriteFile(filepath.Join(root, "hello.txt"), []byte("hello\n"), 0o644); err != nil {
		t.Fatalf("seed: %v", err)
	}
	srv := httptest.NewServer(newMux(root))
	t.Cleanup(srv.Close)
	return srv, root
}

func TestPingEndpoint(t *testing.T) {
	srv, _ := newTestServer(t)

	resp, err := http.Get(srv.URL + "/__ping__")
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("status: got %d, want 200", resp.StatusCode)
	}
}

func TestStaticFileServed(t *testing.T) {
	srv, _ := newTestServer(t)

	resp, err := http.Get(srv.URL + "/hello.txt")
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("status: got %d, want 200", resp.StatusCode)
	}
	body, _ := io.ReadAll(resp.Body)
	if string(body) != "hello\n" {
		t.Fatalf("body: got %q, want %q", string(body), "hello\n")
	}
}

func TestAnnotationPostWritesFile(t *testing.T) {
	srv, root := newTestServer(t)

	payload := []byte(`{"note":"hi"}`)
	url := srv.URL + "/ideas/foo/03-prototypes/alt-1/annotations/note.json"
	resp, err := http.Post(url, "application/json", bytes.NewReader(payload))
	if err != nil {
		t.Fatalf("post: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("status: got %d, want 201", resp.StatusCode)
	}

	diskPath := filepath.Join(root, "ideas", "foo", "03-prototypes", "alt-1", "annotations", "note.json")
	got, err := os.ReadFile(diskPath)
	if err != nil {
		t.Fatalf("read file: %v", err)
	}
	if !bytes.Equal(got, payload) {
		t.Fatalf("body: got %q, want %q", got, payload)
	}
}

func TestAnnotationPostRejectsTraversal(t *testing.T) {
	srv, _ := newTestServer(t)

	resp, err := http.Post(
		srv.URL+"/ideas/../../etc/passwd/annotations/x.json",
		"application/json",
		strings.NewReader(`{}`),
	)
	if err != nil {
		t.Fatalf("post: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("status: got %d, want 400", resp.StatusCode)
	}
}

func TestAnnotationPostRejectsNonAnnotationsPath(t *testing.T) {
	srv, _ := newTestServer(t)

	resp, err := http.Post(
		srv.URL+"/ideas/foo/random.json",
		"application/json",
		strings.NewReader(`{}`),
	)
	if err != nil {
		t.Fatalf("post: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("status: got %d, want 400", resp.StatusCode)
	}
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd server && go test ./... -run 'TestPing|TestStatic|TestAnnotation' -v`
Expected: FAIL — `newMux` currently returns `http.NotFoundHandler()`, so every response is 404.

---

## Task 5: Implement HTTP handlers

**Files:**
- Modify: `server/main.go`
- Create: `server/handlers.go`

- [ ] **Step 1: Remove the stub newMux from main.go**

In `server/main.go`, delete these lines (they will be replaced by the real implementation in handlers.go — if both exist, the package will not compile due to a duplicate `newMux` definition):

```go
// newMux is defined in handlers.go (will be created in a later task).
// For now, a temporary stub lives here so the package compiles.
func newMux(root string) http.Handler {
	return http.NotFoundHandler()
}
```

Keep the `"net/http"` import — `http.ListenAndServe` still uses it.

- [ ] **Step 2: Write the handlers**

Write `server/handlers.go`:

```go
package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

// newMux builds the HTTP handler for the server. root is the absolute
// disk path that all file operations are confined to.
//
// We deliberately use a plain HandlerFunc rather than http.ServeMux:
// ServeMux applies path.Clean to the request path before routing, which
// would collapse `..` segments and prevent ValidateAnnotationPath from
// rejecting traversal attacks. A flat HandlerFunc preserves the raw
// (decoded) request path in r.URL.Path so validation sees the truth.
func newMux(root string) http.Handler {
	fs := http.FileServer(http.Dir(root))
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/__ping__" {
			handlePing(w, r)
			return
		}
		if r.Method == http.MethodPost {
			handleAnnotationPost(root, w, r)
			return
		}
		fs.ServeHTTP(w, r)
	})
}

func handlePing(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "ok")
}

func handleAnnotationPost(root string, w http.ResponseWriter, r *http.Request) {
	// Only accept POSTs that land inside some .../annotations/ directory.
	if !strings.Contains(r.URL.Path, "/annotations/") {
		http.Error(w, "POST only accepted under an annotations/ directory", http.StatusBadRequest)
		return
	}

	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	diskPath, err := ValidateAnnotationPath(root, urlPath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := os.MkdirAll(filepath.Dir(diskPath), 0o755); err != nil {
		http.Error(w, "mkdir failed", http.StatusInternalServerError)
		return
	}
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "read body", http.StatusInternalServerError)
		return
	}
	if err := os.WriteFile(diskPath, body, 0o644); err != nil {
		http.Error(w, "write failed", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
}
```

- [ ] **Step 3: Run all tests**

Run: `cd server && go test ./... -v`
Expected: all tests PASS — `TestValidateAnnotationPath` sub-tests, `TestPingEndpoint`, `TestStaticFileServed`, `TestAnnotationPostWritesFile`, `TestAnnotationPostRejectsTraversal`, `TestAnnotationPostRejectsNonAnnotationsPath`.

- [ ] **Step 4: Run the binary manually for sanity**

Run (in one terminal):
```bash
cd server && go run . --root /tmp --port 4788
```

Run (in another terminal):
```bash
curl -i http://127.0.0.1:4788/__ping__
```
Expected: `HTTP/1.1 200 OK` followed by `ok`.

Stop the server with Ctrl-C in the first terminal.

- [ ] **Step 5: Commit**

```bash
git add server/handlers.go server/main.go server/main_test.go
git commit -m "server: implement ping, static, and annotation-POST handlers"
```

---

## Task 6: Add outside-root rejection test

This is a belt-and-suspenders test. The handler relies on `ValidateAnnotationPath` which we tested in Task 2, but we want an end-to-end proof that a POST which would escape root is rejected at the HTTP layer even if a path-validation bug is introduced later.

**Files:**
- Modify: `server/main_test.go`

- [ ] **Step 1: Add the test function**

Append to `server/main_test.go`:

```go
func TestAnnotationPostRejectsOutsideRoot(t *testing.T) {
	srv, root := newTestServer(t)

	// Pre-create a sibling directory OUTSIDE root that the attack would
	// target. If the attack succeeded, a file would appear here.
	outside := filepath.Join(root, "..", "outside-target")
	if err := os.MkdirAll(outside, 0o755); err != nil {
		t.Fatalf("seed outside: %v", err)
	}
	t.Cleanup(func() { os.RemoveAll(outside) })

	resp, err := http.Post(
		srv.URL+"/%2e%2e/outside-target/annotations/gotcha.json",
		"application/json",
		strings.NewReader(`{}`),
	)
	if err != nil {
		t.Fatalf("post: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusCreated {
		t.Fatalf("attack succeeded! status %d", resp.StatusCode)
	}

	// The outside file must NOT exist.
	if _, err := os.Stat(filepath.Join(outside, "annotations", "gotcha.json")); !os.IsNotExist(err) {
		t.Fatalf("file was written outside root (err=%v)", err)
	}
}
```

- [ ] **Step 2: Run to verify it passes**

Run: `cd server && go test ./... -run TestAnnotationPostRejectsOutsideRoot -v`
Expected: PASS. (Go's `http.ServeMux` normalizes `%2e%2e` to `..` before routing, which is caught by the segment check in `ValidateAnnotationPath`.)

- [ ] **Step 3: Commit**

```bash
git add server/main_test.go
git commit -m "server: belt-and-suspenders test for URL-encoded traversal"
```

---

## Task 7: Cross-compile script

**Files:**
- Create: `scripts/build-release.sh`

- [ ] **Step 1: Write the script**

Write `scripts/build-release.sh`:

```bash
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
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x scripts/build-release.sh`

- [ ] **Step 3: Run it and verify all four binaries are produced**

Run: `bash scripts/build-release.sh 0.1.0-test`
Expected: Four lines of `Building …`, then a `Built artifacts:` list showing all four binaries in `dist/`. Each file is a non-empty binary (4–8 MB range).

- [ ] **Step 4: Verify the host-matching binary actually runs**

Determine your OS/arch: `go env GOOS GOARCH`

Run the matching binary:
```bash
# Example for macOS arm64:
./dist/proto-maker-server-darwin-arm64 --root /tmp --port 4799 &
SERVER_PID=$!
sleep 0.3
curl -sf http://127.0.0.1:4799/__ping__
kill $SERVER_PID
```
Expected: `ok` printed, no curl error, binary exits cleanly on SIGTERM.

- [ ] **Step 5: Clean dist and commit**

```bash
rm -rf dist
# dist/ is build output; add to .gitignore
printf "\ndist/\n" >> .gitignore
git add scripts/build-release.sh .gitignore
git commit -m "server: cross-compile release script for 4 targets"
```

---

## Task 8: Server smoke test script

**Files:**
- Create: `tests/server-smoke.sh`

- [ ] **Step 1: Write the smoke test**

Write `tests/server-smoke.sh`:

```bash
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
code=$(curl -so /dev/null -w "%{http_code}" -X POST \
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
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x tests/server-smoke.sh`

- [ ] **Step 3: Build and smoke-test the host binary**

Run:
```bash
bash scripts/build-release.sh 0.1.0-test
# Pick the binary matching your host:
HOST_OS=$(go env GOOS)
HOST_ARCH=$(go env GOARCH)
BIN="dist/proto-maker-server-${HOST_OS}-${HOST_ARCH}"
bash tests/server-smoke.sh "$BIN"
```
Expected: five `PASS` lines, no `FAIL`, exit code 0.

- [ ] **Step 4: Clean and commit**

```bash
rm -rf dist
git add tests/server-smoke.sh
git commit -m "server: end-to-end smoke test script"
```

---

## Task 9: Document the server package

**Files:**
- Create: `server/README.md`

- [ ] **Step 1: Write the README**

Write `server/README.md`:

```markdown
# proto-maker-server

A tiny static-file HTTP server. Binds to `127.0.0.1` only. Used by the
proto-maker `/preview` skill to serve a PM's ideas repo and persist
stakeholder annotations from the wireframe overlay.

## Endpoints

| Method | Path | Behavior |
|---|---|---|
| `GET` | `/__ping__` | `200 ok` — overlay uses this to detect the server |
| `POST` | `/<path>/annotations/<file>.json` | Writes body to disk under `--root`. Returns `201`. Rejects `..`, absolute paths, and paths escaping root with `400`. |
| `GET` | anything else | Serves static files under `--root` |

## Flags

- `--port` (default `4788`): TCP port to listen on.
- `--root` (default `.`): document root. All file operations are confined here.

## Building

Host build:
```bash
cd server && go build -o proto-maker-server .
```

Release build (all 4 targets):
```bash
bash scripts/build-release.sh 0.1.0
```

## Testing

Unit + integration tests (Go):
```bash
cd server && go test ./...
```

End-to-end smoke (against a built binary):
```bash
bash tests/server-smoke.sh dist/proto-maker-server-$(go env GOOS)-$(go env GOARCH)
```

## Security model

The server is designed to be safe ONLY on `localhost`. It is not a
hardened network service. It does enforce:

- Binding to `127.0.0.1` (not `0.0.0.0`)
- Rejecting path traversal (`..` in any segment, URL-encoded or not)
- Rejecting absolute paths
- Rejecting paths that `filepath.Rel` reports as escaping the root
- Confining POST writes to directories named `annotations/`

It does NOT authenticate callers. Do not expose this server to a
network. Running behind a reverse proxy or binding to `0.0.0.0` is
unsupported.
```

- [ ] **Step 2: Commit**

```bash
git add server/README.md
git commit -m "server: README documenting endpoints, flags, and security model"
```

---

## Task 10: Final verification

- [ ] **Step 1: Run every test from a clean state**

```bash
cd server && go test ./... -v && cd ..
bash scripts/build-release.sh 0.1.0
HOST_OS=$(go env GOOS)
HOST_ARCH=$(go env GOARCH)
bash tests/server-smoke.sh "dist/proto-maker-server-${HOST_OS}-${HOST_ARCH}"
rm -rf dist
```

Expected:
- All Go tests PASS.
- All 4 binaries build.
- All 5 smoke-test assertions PASS.

- [ ] **Step 2: Confirm the git log tells a coherent story**

Run: `git log --oneline`
Expected: a sequence of commits along the lines of:
```
server: README documenting endpoints, flags, and security model
server: end-to-end smoke test script
server: cross-compile release script for 4 targets
server: belt-and-suspenders test for URL-encoded traversal
server: implement ping, static, and annotation-POST handlers
server: path validation with traversal rejection
server: init Go module and main skeleton
Add proto-maker v1 design spec
```

- [ ] **Step 3: Done**

This plan is complete. The server subsystem is verified end-to-end on the dev host. Cross-platform runtime verification (Windows, remote macOS, remote Linux) is tracked in spec §10.4 and happens during release testing once the installer (Plan 4) exists.

---

## Spec Coverage Self-Check

Mapping spec requirements → tasks:

| Spec § | Requirement | Task |
|---|---|---|
| §7.1 | Serve static files from a configured root | Task 5 |
| §7.1 | `POST /<path>/annotations/<file>.json` writes body to disk | Task 5 |
| §7.1 | `GET /__ping__` returns 200 | Task 5 |
| §7.2 | Go stdlib only, ~50–100 LOC | Task 5 (final line count verified in Task 10) |
| §7.2 | Binds to `localhost` only | Task 1 (hardcoded `127.0.0.1`) |
| §7.2 | Rejects paths with `..` | Tasks 3, 5, 6 |
| §7.2 | Rejects absolute paths | Task 3 |
| §7.2 | Configurable port (default 4788) and root (default cwd) | Task 1 |
| §7.3 | Cross-compiled to 4 targets | Task 7 |
| §10.3 | Server smoke test on all 3 platforms (CI) | Task 8 (script); CI matrix is Plan 4 |
| §10.6 | No fuzzing / load testing | explicitly out of scope |

**Gaps intentionally deferred:**
- CI setup (`scripts/build-release.sh` works locally; wiring to GitHub Actions is in Plan 4).
- Signing workarounds for Windows/macOS (documented in Plan 4's installer work).
- Runtime verification on Windows and remote Linux (requires target hardware; in spec §10.4 manual checklist).

---

## Plan coverage note

This is **Plan 1 of 4**. Remaining plans to be written:
- **Plan 2:** Wireframe template (Pico.css + components.css + dual-mode annotations.js)
- **Plan 3:** Skills & agents (AGENTS.md + 11 skills + 4 subagent definitions + sample dogfood idea)
- **Plan 4:** Installer & release tooling (install.sh, install.ps1, CI, release packaging)

Plans 2 and 3 depend on this plan's completion (Plan 3's `/preview` skill launches this binary, Plan 2's annotations.js talks to these endpoints). Plan 4 depends on all three.
