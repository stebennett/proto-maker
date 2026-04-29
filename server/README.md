# proto-maker-server

A tiny static-file HTTP server. Binds to `127.0.0.1` only. Used by the
proto-maker `$preview` skill to serve a PM's ideas repo and persist
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
