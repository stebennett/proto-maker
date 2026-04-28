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
