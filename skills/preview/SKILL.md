---
name: preview
description: Starts the local proto-maker-server in the background so the wireframe overlay can persist annotations to disk. Idempotent. Run once per Codex session before reviewing prototypes in the browser.
---

# /preview — start the local prototype server

## When to use

Run this once per Codex session, BEFORE the PM opens prototype HTML in their
browser to review or have stakeholders annotate. Without it, the annotation
overlay falls back to offline mode (localStorage + clipboard).

## Process

1. Probe whether the server is already running:
   ```bash
   curl -sf http://127.0.0.1:4788/__ping__ >/dev/null 2>&1 && echo running
   ```
   If it prints `running`, tell the PM: "Preview server already running at
   http://127.0.0.1:4788/" and stop.

2. Otherwise, find the server binary on PATH:
   ```bash
   command -v proto-maker-server
   ```
   If empty, tell the PM:
   "I can't find the proto-maker-server binary. Reinstall proto-maker
   (rerun the installer you used originally). Then try `/preview` again."
   Stop.

3. Pick a free port from 4788–4798 and start the server in the background,
   rooted at the current working directory. The loop tries each port in turn,
   confirms the server actually responds (so we don't capture a port that some
   unrelated process is squatting on without serving), and records the port
   that succeeded:
   ```bash
   PROTO_MAKER_PORT=""
   for PORT in 4788 4789 4790 4791 4792 4793 4794 4795 4796 4797 4798; do
     proto-maker-server --port "$PORT" --root . \
       > /tmp/proto-maker-server.log 2>&1 &
     SERVER_PID=$!
     for i in 1 2 3 4 5 6 7 8 9 10; do
       if curl -sf "http://127.0.0.1:$PORT/__ping__" >/dev/null 2>&1; then
         PROTO_MAKER_PORT="$PORT"
         break
       fi
       sleep 0.2
     done
     if [ -n "$PROTO_MAKER_PORT" ]; then break; fi
     # This port didn't come up: kill our spawned process and try the next.
     kill "$SERVER_PID" 2>/dev/null || true
     wait "$SERVER_PID" 2>/dev/null || true
   done
   if [ -z "$PROTO_MAKER_PORT" ]; then
     echo "Could not bind any port in 4788-4798"
     cat /tmp/proto-maker-server.log
     exit 1
   fi
   echo "started on port $PROTO_MAKER_PORT"
   ```
   If the loop exits without binding, surface `/tmp/proto-maker-server.log`
   to the PM and stop.

4. Tell the PM, substituting `$PROTO_MAKER_PORT` into the URL:
   "Preview server started at http://127.0.0.1:$PROTO_MAKER_PORT/.
   To view a prototype, open: http://127.0.0.1:$PROTO_MAKER_PORT/ideas/<idea>/03-prototypes/<alt>/index.html
   in a browser. The annotation overlay will save notes directly to disk.
   The server stops when you close this terminal session."

## Constraints

- Do NOT instruct the PM to run any commands themselves. You spawn the server.
- Do NOT leave the server in the foreground (would block the Codex session).
- Do NOT touch firewall rules or expose to non-loopback addresses.
