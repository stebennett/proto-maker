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
