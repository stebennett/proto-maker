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
