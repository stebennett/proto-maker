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
