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