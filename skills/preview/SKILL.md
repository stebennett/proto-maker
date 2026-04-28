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

3. Start the server in the background, rooted at the current working directory:
   ```bash
   proto-maker-server --port 4788 --root . > /tmp/proto-maker-server.log 2>&1 &
   ```

4. Wait briefly and re-probe:
   ```bash
   for i in 1 2 3 4 5 6 7 8 9 10; do
     if curl -sf http://127.0.0.1:4788/__ping__ >/dev/null 2>&1; then
       echo started; break
     fi
     sleep 0.2
   done
   ```
   If still not responding, surface `/tmp/proto-maker-server.log` to the PM.

5. Tell the PM:
   "Preview server started at http://127.0.0.1:4788/.
   To view a prototype, open: http://127.0.0.1:4788/ideas/<idea>/03-prototypes/<alt>/index.html
   in a browser. The annotation overlay will save notes directly to disk.
   The server stops when you close this terminal session."

## Port-in-use handling

If port 4788 is in use by something other than proto-maker-server (the
`/__ping__` probe fails AND a process holds 4788), retry with --port 4789,
then 4790, up to 4798. Report the actual URL used.

## Constraints

- Do NOT instruct the PM to run any commands themselves. You spawn the server.
- Do NOT leave the server in the foreground (would block the Codex session).
- Do NOT touch firewall rules or expose to non-loopback addresses.
