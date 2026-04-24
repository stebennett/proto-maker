# Proto-Maker Wireframe Template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the static wireframe template (HTML skeleton + Pico.css + custom mock components + dual-mode annotation overlay JS) that the Designer subagent uses as the foundation for every prototype screen, and that stakeholders interact with via a browser.

**Architecture:** Vanilla HTML/CSS/JS, no build step, no framework. Pico.css provides typography and form primitives; `components.css` adds wireframe-specific mocks (`.mock-nav`, `.mock-table`, `.mock-modal`, `mark.tbd`) and the annotation overlay styling. `annotations.js` probes `GET /__ping__` on page load and switches between "online" mode (POST annotations to disk via the proto-maker server) and "offline" mode (localStorage + copy-to-clipboard for stakeholders viewing an extracted zip from `file://`).

**Tech Stack:** HTML5, CSS, vanilla JavaScript (ES6, no transpilation). Tests run as a static HTML page in a real browser — no Node, no jsdom.

**Depends on:** Plan 1 (the proto-maker server) for live testing of online mode.

---

## Scope

**This plan delivers:**
- `templates/wireframe-base/` directory with index.html, pico.min.css, components.css, annotations.js
- A hand-crafted 3-screen demo prototype at `templates/sample-demo/` proving the template works end-to-end
- An interactive JS test harness at `tests/wireframe-test.html` that asserts annotations.js behavior in a browser
- A manual visual verification checklist

**This plan does NOT deliver:**
- The Designer subagent that emits HTML using this template (Plan 3)
- Auto-generated prototype landing pages (Plan 3 — `03-prototypes/index.html`)

**End state of this plan:** A developer can open `tests/wireframe-test.html` in a browser and see all annotation tests PASS. They can also open `templates/sample-demo/index.html`, click between three screens, add annotations in offline mode, and copy them to the clipboard.

---

## File Structure

```
templates/
  wireframe-base/
    index.html             # screen template — copy this to start a new screen
    pico.min.css           # vendored Pico.css v2.x
    components.css         # mock-* primitives, .tbd, annotation overlay
    annotations.js         # dual-mode overlay logic
  sample-demo/             # hand-crafted prototype using the template
    index.html             # landing
    screen-1.html
    screen-2.html
    screen-3.html
tests/
  wireframe-test.html      # browser-runnable test harness for annotations.js
```

**Boundaries:**
- `annotations.js` is the only file with non-trivial logic. It owns mode detection, persistence, and the overlay UI.
- `components.css` is purely presentational. No selectors that change behavior.
- The screen template (`index.html`) is structural only — no business logic.

---

## Task 1: Vendor Pico.css

**Files:**
- Create: `templates/wireframe-base/pico.min.css`

- [ ] **Step 1: Download Pico.css v2 minified**

Run:
```bash
mkdir -p templates/wireframe-base
curl -fsSL https://unpkg.com/@picocss/pico@2.0.6/css/pico.min.css \
  -o templates/wireframe-base/pico.min.css
```

Verify the file exists and is ~75KB:
```bash
ls -lh templates/wireframe-base/pico.min.css
```

Expected: file present, size between 50KB and 100KB.

- [ ] **Step 2: Pin the version in a NOTICE file**

Write `templates/wireframe-base/PICO-NOTICE.md`:

```markdown
# Pico.css

Vendored copy of Pico.css v2.0.6 (https://picocss.com).
Licensed under the MIT License.

Source: https://unpkg.com/@picocss/pico@2.0.6/css/pico.min.css
Downloaded: 2026-04-24
```

- [ ] **Step 3: Commit**

```bash
git add templates/wireframe-base/pico.min.css templates/wireframe-base/PICO-NOTICE.md
git commit -m "template: vendor Pico.css v2.0.6"
```

---

## Task 2: Write components.css

**Files:**
- Create: `templates/wireframe-base/components.css`

- [ ] **Step 1: Write the stylesheet**

Write `templates/wireframe-base/components.css`:

```css
/*
 * proto-maker wireframe components
 *
 * Layered on top of Pico.css. Provides mock primitives that read as
 * "deliberately unfinished" — clean lines, no decorative styling, just
 * enough structure for stakeholders to grasp layout and flow.
 *
 * Conventions:
 *   .mock-*  : structural placeholders (nav, sidebar, content area, table)
 *   mark.tbd : explicit handwaving callouts that propagate to user stories
 *   .anno-*  : annotation overlay UI (panel, button, list)
 */

/* ---- Wireframe layout primitives ---- */

.mock-nav {
  border-bottom: 1px solid var(--pico-muted-border-color, #ccc);
  padding: 0.6rem 1rem;
  display: flex;
  gap: 1.25rem;
  align-items: center;
  background: var(--pico-card-background-color, #fff);
}
.mock-nav .brand {
  font-weight: 700;
  margin-right: auto;
}

.mock-sidebar {
  border-right: 1px solid var(--pico-muted-border-color, #ccc);
  padding: 1rem;
  min-width: 180px;
  background: var(--pico-card-background-color, #fff);
}
.mock-content {
  padding: 1.5rem;
  flex: 1 1 auto;
}
.mock-layout {
  display: flex;
  align-items: stretch;
  min-height: 60vh;
}

.mock-table {
  width: 100%;
  border-collapse: collapse;
}
.mock-table th, .mock-table td {
  border-bottom: 1px solid var(--pico-muted-border-color, #ddd);
  padding: 0.5rem 0.75rem;
  text-align: left;
}
.mock-table th {
  font-weight: 600;
  background: var(--pico-card-sectioning-background-color, #f7f7f7);
}

.mock-card {
  border: 1px solid var(--pico-muted-border-color, #ddd);
  border-radius: var(--pico-border-radius, 4px);
  padding: 1rem;
}

.mock-modal {
  border: 1px solid var(--pico-muted-border-color, #ccc);
  border-radius: var(--pico-border-radius, 6px);
  padding: 1.5rem;
  max-width: 480px;
  margin: 2rem auto;
  background: var(--pico-card-background-color, #fff);
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}
.mock-modal-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.35);
  display: flex; align-items: center; justify-content: center;
  z-index: 50;
}
.mock-modal-overlay[hidden] { display: none; }

/* ---- TBD callout ---- */

mark.tbd {
  background: #fff3bf;
  color: #5c4400;
  border-bottom: 1px dashed #c9a200;
  padding: 0 0.2em;
}
mark.tbd::before { content: "TBD: "; font-weight: 700; }

/* ---- Annotation overlay ---- */

.anno-button {
  position: fixed;
  bottom: 1rem;
  right: 1rem;
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  border: 1px solid var(--pico-muted-border-color, #aaa);
  background: var(--pico-card-background-color, #fff);
  font-size: 1.25rem;
  cursor: pointer;
  z-index: 100;
  box-shadow: 0 2px 6px rgba(0,0,0,0.15);
}

.anno-panel {
  position: fixed;
  bottom: 4rem;
  right: 1rem;
  width: 320px;
  max-height: 60vh;
  background: var(--pico-card-background-color, #fff);
  border: 1px solid var(--pico-muted-border-color, #aaa);
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.18);
  display: flex;
  flex-direction: column;
  z-index: 100;
  overflow: hidden;
}
.anno-panel[hidden] { display: none; }
.anno-panel header {
  padding: 0.5rem 0.75rem;
  border-bottom: 1px solid var(--pico-muted-border-color, #ddd);
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.85rem;
}
.anno-panel .anno-mode {
  font-size: 0.75rem;
  padding: 0.1rem 0.4rem;
  border-radius: 3px;
}
.anno-panel .anno-mode.online { background: #c8f7c5; color: #1a5e1a; }
.anno-panel .anno-mode.offline { background: #ffe0b2; color: #6e3a00; }
.anno-panel textarea {
  margin: 0.5rem; min-height: 4rem; resize: vertical;
}
.anno-panel .anno-actions {
  display: flex; gap: 0.5rem; padding: 0 0.5rem 0.5rem;
}
.anno-panel ul {
  list-style: none;
  padding: 0 0.5rem 0.5rem;
  margin: 0;
  overflow-y: auto;
  font-size: 0.85rem;
}
.anno-panel ul li {
  padding: 0.4rem;
  border-top: 1px solid var(--pico-muted-border-color, #eee);
}
.anno-panel ul li time { color: #666; font-size: 0.75rem; display: block; }
```

- [ ] **Step 2: Commit**

```bash
git add templates/wireframe-base/components.css
git commit -m "template: components.css with mock primitives, TBD, and annotation overlay styles"
```

---

## Task 3: Write the screen template

**Files:**
- Create: `templates/wireframe-base/index.html`

- [ ] **Step 1: Write the template**

Write `templates/wireframe-base/index.html`:

```html
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{SCREEN_TITLE}} — {{IDEA_NAME}}</title>
  <link rel="stylesheet" href="../../../.proto-maker-assets/pico.min.css">
  <link rel="stylesheet" href="../../../.proto-maker-assets/components.css">
</head>
<body>
  <nav class="mock-nav">
    <span class="brand">{{PRODUCT_NAME}}</span>
    <a href="index.html">Home</a>
    <!-- Add more nav links per screen as needed -->
  </nav>

  <main class="container">
    <h1>{{SCREEN_TITLE}}</h1>

    <!-- Screen content goes here. Use mock-* primitives from components.css. -->
    <p class="muted">Replace this placeholder with the wireframe for this screen.</p>

  </main>

  <script src="../../../.proto-maker-assets/annotations.js"></script>
</body>
</html>
```

Note on the `../../../.proto-maker-assets/` paths: the template lives at `ideas/<slug>/03-prototypes/alt-X/screen-N.html`, three directories deep from the ideas-repo root. The Designer subagent (Plan 3) will be instructed to copy `pico.min.css`, `components.css`, and `annotations.js` to `<ideas-repo>/.proto-maker-assets/` once per ideas repo, so all prototypes share one copy.

- [ ] **Step 2: Commit**

```bash
git add templates/wireframe-base/index.html
git commit -m "template: screen-template HTML scaffold"
```

---

## Task 4: Write the JS test harness skeleton

**Files:**
- Create: `tests/wireframe-test.html`

- [ ] **Step 1: Write the harness**

Write `tests/wireframe-test.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>annotations.js test harness</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 720px; margin: 2rem auto; padding: 0 1rem; }
    .pass { color: #1a5e1a; }
    .fail { color: #b00020; font-weight: 700; }
    .test { padding: 0.25rem 0; border-bottom: 1px solid #eee; }
    pre { background: #f7f7f7; padding: 0.5rem; overflow-x: auto; }
  </style>
</head>
<body>
  <h1>annotations.js test harness</h1>
  <p>Open this file in a browser. All assertions should be green.</p>
  <div id="summary"></div>
  <div id="results"></div>

  <!--
    Mock window.fetch and navigator.clipboard BEFORE loading annotations.js
    so the module sees our mocks when it initializes.
  -->
  <script>
    window.__testFetchCalls = [];
    window.__testFetchResponse = { ok: true, status: 200 };
    window.__testFetchShouldThrow = false;

    window.fetch = (url, opts) => {
      window.__testFetchCalls.push({ url, opts });
      if (window.__testFetchShouldThrow) {
        return Promise.reject(new Error('mock network failure'));
      }
      return Promise.resolve(window.__testFetchResponse);
    };

    window.__testClipboard = null;
    if (!navigator.clipboard) {
      Object.defineProperty(navigator, 'clipboard', { value: {}, writable: true });
    }
    navigator.clipboard.writeText = (text) => {
      window.__testClipboard = text;
      return Promise.resolve();
    };

    // Each test resets state via this helper.
    window.__testReset = () => {
      window.__testFetchCalls = [];
      window.__testFetchResponse = { ok: true, status: 200 };
      window.__testFetchShouldThrow = false;
      window.__testClipboard = null;
      localStorage.clear();
    };
  </script>

  <script src="../templates/wireframe-base/annotations.js"></script>

  <script>
    const results = document.getElementById('results');
    const summary = document.getElementById('summary');
    let pass = 0, fail = 0;

    function assert(label, condition, detail) {
      const div = document.createElement('div');
      div.className = 'test ' + (condition ? 'pass' : 'fail');
      div.textContent = (condition ? 'PASS' : 'FAIL') + ': ' + label;
      if (!condition && detail) {
        const pre = document.createElement('pre');
        pre.textContent = JSON.stringify(detail, null, 2);
        div.appendChild(pre);
      }
      results.appendChild(div);
      if (condition) pass++; else fail++;
    }

    async function runAllTests() {
      // Tests are appended in subsequent tasks. For now, verify the test
      // framework itself is wired up:
      window.__testReset();
      assert('test framework loads annotations.js', typeof window.ProtoMakerAnnotations === 'object',
        { ProtoMakerAnnotations: typeof window.ProtoMakerAnnotations });

      summary.textContent = `${pass} passed, ${fail} failed`;
      summary.className = fail === 0 ? 'pass' : 'fail';
    }

    runAllTests();
  </script>
</body>
</html>
```

- [ ] **Step 2: Open in a browser to verify the framework loads**

Run (macOS): `open tests/wireframe-test.html`
Or (Linux): `xdg-open tests/wireframe-test.html`

Expected: page loads. The single test FAILS with "test framework loads annotations.js" — this is correct, because `annotations.js` doesn't exist yet.

- [ ] **Step 3: Commit**

```bash
git add tests/wireframe-test.html
git commit -m "template: browser-runnable test harness for annotations.js"
```

---

## Task 5: Implement annotations.js — mode detection

**Files:**
- Create: `templates/wireframe-base/annotations.js`
- Modify: `tests/wireframe-test.html`

- [ ] **Step 1: Add mode-detection assertions to the test harness**

In `tests/wireframe-test.html`, replace the body of `runAllTests()` with:

```javascript
async function runAllTests() {
  // ---- Test 1: framework loads ----
  window.__testReset();
  assert('framework: annotations module exposed', typeof window.ProtoMakerAnnotations === 'object');

  // ---- Test 2: probes /__ping__ on init ----
  window.__testReset();
  await window.ProtoMakerAnnotations.init({ screen: 'screen-1.html' });
  assert(
    'init probes /__ping__',
    window.__testFetchCalls.some(c => c.url === '/__ping__'),
    { fetchCalls: window.__testFetchCalls }
  );

  // ---- Test 3: detects online when ping returns 200 ----
  window.__testReset();
  window.__testFetchResponse = { ok: true, status: 200 };
  const onlineOverlay = await window.ProtoMakerAnnotations.init({ screen: 'screen-1.html' });
  assert('mode is online when ping succeeds', onlineOverlay.mode === 'online',
    { mode: onlineOverlay.mode });

  // ---- Test 4: falls back to offline when ping throws ----
  window.__testReset();
  window.__testFetchShouldThrow = true;
  const offlineOverlay = await window.ProtoMakerAnnotations.init({ screen: 'screen-1.html' });
  assert('mode is offline when ping throws', offlineOverlay.mode === 'offline',
    { mode: offlineOverlay.mode });

  // ---- Test 5: falls back to offline when ping returns non-200 ----
  window.__testReset();
  window.__testFetchResponse = { ok: false, status: 404 };
  const offline2 = await window.ProtoMakerAnnotations.init({ screen: 'screen-1.html' });
  assert('mode is offline when ping returns 404', offline2.mode === 'offline');

  summary.textContent = `${pass} passed, ${fail} failed`;
  summary.className = fail === 0 ? 'pass' : 'fail';
}
```

- [ ] **Step 2: Reload the harness — confirm tests fail**

Reload `tests/wireframe-test.html` in your browser. Expected: tests 1–5 all FAIL because `annotations.js` doesn't yet exist.

- [ ] **Step 3: Implement annotations.js (mode detection only)**

Write `templates/wireframe-base/annotations.js`:

```javascript
/*
 * proto-maker annotation overlay
 *
 * Dual-mode overlay for stakeholders to leave structured notes on a
 * wireframe screen. Probes the local proto-maker server at /__ping__
 * on init; if reachable, "online" mode POSTs annotations to disk.
 * Otherwise, "offline" mode persists to localStorage and exposes a
 * "Copy notes" button that places structured JSON on the clipboard.
 *
 * Public surface:
 *   await ProtoMakerAnnotations.init({ screen, path })
 *     → returns the overlay object with .mode in {'online', 'offline'}
 *
 * The init function is idempotent — calling it twice on the same page
 * is a no-op (returns the existing overlay).
 */

(function (global) {
  let activeOverlay = null;

  async function detectMode() {
    try {
      const res = await fetch('/__ping__', { method: 'GET' });
      if (res && res.ok) return 'online';
      return 'offline';
    } catch (_e) {
      return 'offline';
    }
  }

  async function init(opts) {
    if (activeOverlay) return activeOverlay;
    const screen = (opts && opts.screen) || 'unknown.html';
    const path = (opts && opts.path) || '';
    const mode = await detectMode();
    activeOverlay = { mode, screen, path, notes: [] };
    return activeOverlay;
  }

  global.ProtoMakerAnnotations = { init };
})(typeof window !== 'undefined' ? window : this);
```

- [ ] **Step 4: Reload the harness — confirm tests 1–5 PASS**

Reload `tests/wireframe-test.html`. Expected: 5 passed, 0 failed.

- [ ] **Step 5: Commit**

```bash
git add templates/wireframe-base/annotations.js tests/wireframe-test.html
git commit -m "template: annotations.js mode detection (online/offline)"
```

---

## Task 6: Implement annotations.js — adding notes (online + offline)

**Files:**
- Modify: `templates/wireframe-base/annotations.js`
- Modify: `tests/wireframe-test.html`

- [ ] **Step 1: Add note-saving assertions to the harness**

In `tests/wireframe-test.html`, append to `runAllTests()` BEFORE the `summary.textContent = ...` line:

```javascript
  // ---- Test 6: addNote in online mode POSTs to correct endpoint ----
  window.__testReset();
  window.__testFetchResponse = { ok: true, status: 200 };
  const o6 = await window.ProtoMakerAnnotations.init({
    screen: 'screen-2.html',
    path: 'ideas/foo/03-prototypes/alt-1'
  });
  await o6.addNote('Why no back button here?', 'jsmith@acme.com');
  const postCalls = window.__testFetchCalls.filter(c => c.opts && c.opts.method === 'POST');
  assert('online: exactly one POST issued', postCalls.length === 1,
    { postCalls });
  assert('online: POST URL contains annotations/',
    postCalls[0] && postCalls[0].url.includes('/annotations/'),
    { url: postCalls[0] && postCalls[0].url });
  assert('online: POST URL contains the path',
    postCalls[0] && postCalls[0].url.includes('ideas/foo/03-prototypes/alt-1/annotations/'));
  let postedBody = null;
  try { postedBody = JSON.parse(postCalls[0].opts.body); } catch (_e) {}
  assert('online: POST body parses as JSON with note + screen + author',
    postedBody && postedBody.note === 'Why no back button here?'
                && postedBody.screen === 'screen-2.html'
                && postedBody.author === 'jsmith@acme.com',
    { postedBody });

  // ---- Test 7: addNote in offline mode persists to localStorage ----
  window.__testReset();
  window.__testFetchShouldThrow = true;
  const o7 = await window.ProtoMakerAnnotations.init({
    screen: 'screen-3.html',
    path: 'ideas/foo/03-prototypes/alt-2'
  });
  await o7.addNote('Stakeholder offline note', 'guest');
  const stored = JSON.parse(localStorage.getItem('proto-maker-annotations') || '[]');
  assert('offline: localStorage contains 1 note', stored.length === 1, { stored });
  assert('offline: stored note has expected fields',
    stored[0] && stored[0].note === 'Stakeholder offline note'
              && stored[0].screen === 'screen-3.html'
              && stored[0].path === 'ideas/foo/03-prototypes/alt-2',
    { stored });

  // ---- Test 8: offline mode does NOT issue POSTs ----
  assert('offline: zero POSTs to fetch',
    window.__testFetchCalls.filter(c => c.opts && c.opts.method === 'POST').length === 0);
```

- [ ] **Step 2: Reload — confirm tests 6–8 FAIL**

Reload `tests/wireframe-test.html`. Expected: tests 1–5 still pass; 6–8 fail (`addNote` is undefined).

- [ ] **Step 3: Implement addNote in annotations.js**

In `templates/wireframe-base/annotations.js`, replace the `init` function with:

```javascript
  async function postOnline(overlay, note) {
    const url = '/' + overlay.path.replace(/^\/+/, '').replace(/\/+$/, '') +
                '/annotations/' + overlay.screen.replace(/\.html$/, '') +
                '-' + note.timestamp + '.json';
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(note),
    });
    if (!res.ok) throw new Error('POST failed: ' + res.status);
  }

  function persistOffline(note) {
    const key = 'proto-maker-annotations';
    const existing = JSON.parse(localStorage.getItem(key) || '[]');
    existing.push(note);
    localStorage.setItem(key, JSON.stringify(existing));
  }

  async function addNote(text, author) {
    const note = {
      screen: this.screen,
      path: this.path,
      note: text,
      author: author || 'anonymous',
      timestamp: Date.now(),
    };
    if (this.mode === 'online') {
      await postOnline(this, note);
    } else {
      persistOffline(note);
    }
    this.notes.push(note);
    return note;
  }

  async function init(opts) {
    if (activeOverlay) return activeOverlay;
    const screen = (opts && opts.screen) || 'unknown.html';
    const path = (opts && opts.path) || '';
    const mode = await detectMode();
    activeOverlay = { mode, screen, path, notes: [], addNote };
    return activeOverlay;
  }
```

- [ ] **Step 4: Reload — confirm all 8 tests pass**

Reload `tests/wireframe-test.html`. Expected: 8 passed, 0 failed.

- [ ] **Step 5: Commit**

```bash
git add templates/wireframe-base/annotations.js tests/wireframe-test.html
git commit -m "template: annotations.js addNote (online POST + offline localStorage)"
```

---

## Task 7: Implement annotations.js — copy-to-clipboard export

**Files:**
- Modify: `templates/wireframe-base/annotations.js`
- Modify: `tests/wireframe-test.html`

- [ ] **Step 1: Add export assertions to the harness**

Append to `runAllTests()` BEFORE the summary assignment:

```javascript
  // ---- Test 9: exportNotes returns array of stored notes ----
  window.__testReset();
  window.__testFetchShouldThrow = true; // force offline so localStorage is the source
  const o9 = await window.ProtoMakerAnnotations.init({
    screen: 'sX.html', path: 'ideas/x/03-prototypes/alt-1'
  });
  await o9.addNote('first', 'a');
  await o9.addNote('second', 'b');
  const exported = o9.exportNotes();
  assert('exportNotes returns 2 notes', Array.isArray(exported) && exported.length === 2,
    { exported });

  // ---- Test 10: copyNotes writes JSON to clipboard ----
  window.__testReset();
  window.__testFetchShouldThrow = true;
  const o10 = await window.ProtoMakerAnnotations.init({
    screen: 's.html', path: 'ideas/x/03-prototypes/alt-1'
  });
  await o10.addNote('hello', 'me');
  await o10.copyNotes();
  let parsed = null;
  try { parsed = JSON.parse(window.__testClipboard); } catch (_e) {}
  assert('copyNotes wrote JSON to clipboard', parsed && parsed.length === 1
    && parsed[0].note === 'hello', { clipboard: window.__testClipboard });
```

- [ ] **Step 2: Reload — confirm tests 9–10 FAIL**

Expected: 1–8 pass, 9–10 fail.

- [ ] **Step 3: Add exportNotes and copyNotes to annotations.js**

In `templates/wireframe-base/annotations.js`, after `addNote` definition, add:

```javascript
  function exportNotes() {
    if (this.mode === 'online') {
      // In online mode the truth is on disk; we only have what's in this session.
      return this.notes.slice();
    }
    const key = 'proto-maker-annotations';
    return JSON.parse(localStorage.getItem(key) || '[]');
  }

  async function copyNotes() {
    const notes = exportNotes.call(this);
    await navigator.clipboard.writeText(JSON.stringify(notes, null, 2));
    return notes;
  }
```

Then update the `init` function to attach both methods:

```javascript
  async function init(opts) {
    if (activeOverlay) return activeOverlay;
    const screen = (opts && opts.screen) || 'unknown.html';
    const path = (opts && opts.path) || '';
    const mode = await detectMode();
    activeOverlay = { mode, screen, path, notes: [], addNote, exportNotes, copyNotes };
    return activeOverlay;
  }
```

- [ ] **Step 4: Reload — confirm all 10 tests pass**

Expected: 10 passed, 0 failed.

- [ ] **Step 5: Commit**

```bash
git add templates/wireframe-base/annotations.js tests/wireframe-test.html
git commit -m "template: annotations.js exportNotes + copyNotes (clipboard)"
```

---

## Task 8: Implement annotations.js — overlay UI (button + panel)

**Files:**
- Modify: `templates/wireframe-base/annotations.js`

This task adds the user-facing UI. There's no automated test — verification is visual in Task 10.

- [ ] **Step 1: Add the renderUI function and call it from init**

In `templates/wireframe-base/annotations.js`, add before the `init` function:

```javascript
  function renderUI(overlay) {
    if (typeof document === 'undefined') return; // jsdom-less test environments

    // Floating ? button
    const btn = document.createElement('button');
    btn.className = 'anno-button';
    btn.type = 'button';
    btn.textContent = '?';
    btn.title = 'Add annotation';

    // Panel
    const panel = document.createElement('aside');
    panel.className = 'anno-panel';
    panel.hidden = true;
    panel.innerHTML = `
      <header>
        <span>Notes — ${overlay.screen}</span>
        <span class="anno-mode ${overlay.mode}">${overlay.mode}</span>
      </header>
      <textarea placeholder="Leave a note about this screen…"></textarea>
      <div class="anno-actions">
        <button type="button" data-act="add">Save</button>
        <button type="button" data-act="copy">Copy all notes</button>
      </div>
      <ul></ul>
    `;

    document.body.appendChild(btn);
    document.body.appendChild(panel);

    btn.addEventListener('click', () => {
      panel.hidden = !panel.hidden;
      if (!panel.hidden) refreshList();
    });

    const ta = panel.querySelector('textarea');
    panel.querySelector('[data-act=add]').addEventListener('click', async () => {
      const text = ta.value.trim();
      if (!text) return;
      await overlay.addNote(text, prompt('Your name or email (optional):') || 'anonymous');
      ta.value = '';
      refreshList();
    });

    panel.querySelector('[data-act=copy]').addEventListener('click', async () => {
      await overlay.copyNotes();
      const original = panel.querySelector('[data-act=copy]').textContent;
      panel.querySelector('[data-act=copy]').textContent = 'Copied!';
      setTimeout(() => {
        panel.querySelector('[data-act=copy]').textContent = original;
      }, 1500);
    });

    function refreshList() {
      const ul = panel.querySelector('ul');
      ul.innerHTML = '';
      const notes = overlay.exportNotes();
      for (const n of notes) {
        const li = document.createElement('li');
        const t = new Date(n.timestamp).toLocaleString();
        li.innerHTML = `<time>${t} — ${n.author}</time><div>${escapeHtml(n.note)}</div>`;
        ul.appendChild(li);
      }
    }
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
```

- [ ] **Step 2: Call renderUI from init**

Update `init` to invoke `renderUI` when running in a real browser:

```javascript
  async function init(opts) {
    if (activeOverlay) return activeOverlay;
    const screen = (opts && opts.screen) || 'unknown.html';
    const path = (opts && opts.path) || '';
    const mode = await detectMode();
    activeOverlay = { mode, screen, path, notes: [], addNote, exportNotes, copyNotes };
    // Skip UI rendering during tests by checking for our test harness sentinel.
    if (typeof window !== 'undefined' && !window.__testFetchCalls) {
      renderUI(activeOverlay);
    }
    return activeOverlay;
  }
```

The check on `window.__testFetchCalls` is the test sentinel — it exists only when our harness has wired up. In real prototype use, `window.__testFetchCalls` is `undefined`, so `renderUI` runs.

- [ ] **Step 3: Reload the harness — confirm all 10 tests still pass**

Expected: 10 passed, 0 failed. The new `renderUI` doesn't run in test mode because of the sentinel check.

- [ ] **Step 4: Commit**

```bash
git add templates/wireframe-base/annotations.js
git commit -m "template: annotations.js floating button + notes panel UI"
```

---

## Task 9: Build a sample 3-screen demo prototype

**Files:**
- Create: `templates/sample-demo/.proto-maker-assets/pico.min.css` (symlink or copy)
- Create: `templates/sample-demo/.proto-maker-assets/components.css` (symlink or copy)
- Create: `templates/sample-demo/.proto-maker-assets/annotations.js` (symlink or copy)
- Create: `templates/sample-demo/index.html`
- Create: `templates/sample-demo/screen-settings.html`
- Create: `templates/sample-demo/screen-confirm.html`

Note: the templates live at `templates/sample-demo/screen-*.html`, ONE level deep from `templates/`. The template's `<link>` and `<script>` paths use `../../../.proto-maker-assets/` for the production layout (3 levels deep). For the demo, we'll create the assets directly under `sample-demo/.proto-maker-assets/` and use `.proto-maker-assets/` paths in the demo HTML — this keeps the demo self-contained.

- [ ] **Step 1: Create the assets folder by copying**

Run:
```bash
mkdir -p templates/sample-demo/.proto-maker-assets
cp templates/wireframe-base/pico.min.css templates/sample-demo/.proto-maker-assets/
cp templates/wireframe-base/components.css templates/sample-demo/.proto-maker-assets/
cp templates/wireframe-base/annotations.js templates/sample-demo/.proto-maker-assets/
```

- [ ] **Step 2: Write the landing page**

Write `templates/sample-demo/index.html`:

```html
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sample demo — Acme Settings</title>
  <link rel="stylesheet" href=".proto-maker-assets/pico.min.css">
  <link rel="stylesheet" href=".proto-maker-assets/components.css">
</head>
<body>
  <nav class="mock-nav">
    <span class="brand">Acme</span>
    <a href="index.html">Home</a>
    <a href="screen-settings.html">Settings</a>
  </nav>
  <main class="container">
    <h1>Welcome to Acme</h1>
    <p>This is the sample-demo prototype. It exists to verify the wireframe template renders, links work, and the annotation overlay functions in offline mode.</p>
    <article class="mock-card">
      <h3>Try it</h3>
      <ol>
        <li>Click <a href="screen-settings.html">Settings</a> to navigate to a wireframe with a <code>mark.tbd</code> callout.</li>
        <li>From any page, click the <strong>?</strong> button bottom-right to open the annotations panel.</li>
        <li>Click <strong>Copy all notes</strong> to confirm structured JSON is written to your clipboard.</li>
      </ol>
    </article>
  </main>
  <script>
    // Compute path from this HTML's URL so the overlay knows where to POST
    // (irrelevant in offline mode but exercised for parity).
    window.ProtoMakerAnnotations.init({
      screen: 'index.html',
      path: 'templates/sample-demo'
    });
  </script>
  <script src=".proto-maker-assets/annotations.js"></script>
</body>
</html>
```

Wait — the `<script src="...annotations.js">` needs to load BEFORE the inline init call runs. Reorder: the annotations.js script tag must come FIRST, then the init script. Let me correct:

Actually, in the order written, the inline `<script>` references `window.ProtoMakerAnnotations` before it's defined. Reorder the two `<script>` tags so annotations.js loads first:

```html
  <script src=".proto-maker-assets/annotations.js"></script>
  <script>
    window.ProtoMakerAnnotations.init({
      screen: 'index.html',
      path: 'templates/sample-demo'
    });
  </script>
```

Use this order in all three sample HTML files.

- [ ] **Step 3: Write the settings screen**

Write `templates/sample-demo/screen-settings.html`:

```html
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
  <meta charset="utf-8">
  <title>Settings — Acme</title>
  <link rel="stylesheet" href=".proto-maker-assets/pico.min.css">
  <link rel="stylesheet" href=".proto-maker-assets/components.css">
</head>
<body>
  <nav class="mock-nav">
    <span class="brand">Acme</span>
    <a href="index.html">Home</a>
    <a href="screen-settings.html">Settings</a>
  </nav>
  <main class="container">
    <h1>Account settings</h1>

    <article>
      <h3>Theme</h3>
      <label>
        <input type="checkbox" id="dark-mode-toggle">
        Enable dark mode
      </label>
      <p><mark class="tbd">applies only to authenticated users — guest mode keeps light theme</mark></p>
    </article>

    <article>
      <h3>Profile</h3>
      <table class="mock-table">
        <tr><th>Field</th><th>Value</th></tr>
        <tr><td>Name</td><td>Sample User</td></tr>
        <tr><td>Email</td><td>sample@acme.test</td></tr>
      </table>
    </article>

    <a href="screen-confirm.html" role="button">Save changes</a>
  </main>
  <script src=".proto-maker-assets/annotations.js"></script>
  <script>
    window.ProtoMakerAnnotations.init({
      screen: 'screen-settings.html',
      path: 'templates/sample-demo'
    });
    // Demonstrate in-page JS for explanatory interactions:
    document.getElementById('dark-mode-toggle').addEventListener('change', (e) => {
      document.documentElement.dataset.theme = e.target.checked ? 'dark' : 'light';
    });
  </script>
</body>
</html>
```

- [ ] **Step 4: Write the confirmation screen**

Write `templates/sample-demo/screen-confirm.html`:

```html
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
  <meta charset="utf-8">
  <title>Saved — Acme</title>
  <link rel="stylesheet" href=".proto-maker-assets/pico.min.css">
  <link rel="stylesheet" href=".proto-maker-assets/components.css">
</head>
<body>
  <nav class="mock-nav">
    <span class="brand">Acme</span>
    <a href="index.html">Home</a>
    <a href="screen-settings.html">Settings</a>
  </nav>
  <main class="container">
    <article class="mock-card">
      <h2>Settings saved</h2>
      <p>Your changes have been saved.</p>
      <p><mark class="tbd">should this redirect to a confirmation toast on the previous screen instead?</mark></p>
      <a href="screen-settings.html" role="button">Back to settings</a>
    </article>
  </main>
  <script src=".proto-maker-assets/annotations.js"></script>
  <script>
    window.ProtoMakerAnnotations.init({
      screen: 'screen-confirm.html',
      path: 'templates/sample-demo'
    });
  </script>
</body>
</html>
```

- [ ] **Step 5: Commit**

```bash
git add templates/sample-demo/
git commit -m "template: 3-screen sample demo using the wireframe-base template"
```

---

## Task 10: Manual visual verification

This task has no automated test — it's a checklist a developer runs in a real browser.

- [ ] **Step 1: Open the sample demo**

Run:
```bash
open templates/sample-demo/index.html  # macOS
# or
xdg-open templates/sample-demo/index.html  # Linux
```

- [ ] **Step 2: Walk the checklist**

Verify each item in the browser:

- [ ] Landing page renders with header, brand, and two nav links visible
- [ ] Click "Settings" nav link → navigates to settings screen
- [ ] Settings screen shows: heading, dark-mode checkbox, profile table, "Save changes" button
- [ ] The TBD callout (`mark.tbd`) is visually distinct (yellow background, "TBD: " prefix)
- [ ] Toggle the dark-mode checkbox → page theme switches to dark
- [ ] Click "Save changes" → navigates to confirmation screen
- [ ] Confirmation screen shows the "saved" message and a TBD callout
- [ ] Browser back button returns to settings
- [ ] On any screen, click the floating `?` button bottom-right → annotations panel opens
- [ ] Panel header shows "offline" badge (orange) since no server is running
- [ ] Type a note in the textarea, click "Save", optionally enter author when prompted
- [ ] Note appears in the list below with timestamp and author
- [ ] Navigate to another screen, click `?`, see THE SAME note in the list (localStorage is shared across screens by design — this matches stakeholder UX of "one notepad for the whole prototype")
- [ ] Click "Copy all notes" → button text briefly says "Copied!"
- [ ] Paste into a text editor → confirm the clipboard contains valid JSON: an array of objects with `note`, `author`, `screen`, `path`, `timestamp` fields

- [ ] **Step 3: Verify online mode against the running server**

This step requires Plan 1's server binary to exist. If you've completed Plan 1:

Run (in one terminal):
```bash
# Start the server with the demo's parent folder as root.
HOST_OS=$(go env GOOS)
HOST_ARCH=$(go env GOARCH)
bash scripts/build-release.sh dev
./dist/proto-maker-server-${HOST_OS}-${HOST_ARCH} \
  --root templates/sample-demo \
  --port 4788
```

In a browser, open: `http://127.0.0.1:4788/index.html`

- [ ] Annotation panel header shows "online" badge (green)
- [ ] Save a note via the `?` panel
- [ ] Confirm a JSON file appears at `templates/sample-demo/templates/sample-demo/annotations/index-<timestamp>.json`
  (The doubled path is because the demo's `path` parameter says `templates/sample-demo` and the server is rooted at that same folder. In real proto-maker use, the path will be `ideas/<slug>/03-prototypes/<alt>` and the server is rooted at the ideas-repo root — so the file lands at the correct nested location.)
- [ ] Stop the server with Ctrl-C

Clean up: `rm -rf dist`

- [ ] **Step 4: Done**

If every checklist item passes, the wireframe template is verified end-to-end in both modes.

---

## Spec Coverage Self-Check

| Spec § | Requirement | Task |
|---|---|---|
| §6.3 | Pico.css vendored, no CDN | Task 1 |
| §6.3 | `components.css` with mock-* primitives | Task 2 |
| §6.3 | `mark.tbd` convention, visually distinct | Task 2 (CSS); Task 9 (used in sample) |
| §6.3 | `annotations.js` loaded on every screen | Task 3 (template), Task 9 (sample uses it) |
| §6.3 | Online mode probes /__ping__ | Task 5 |
| §6.3 | Online mode POSTs to `/<path>/annotations/<file>.json` | Task 6 |
| §6.3 | Offline mode uses localStorage | Task 6 |
| §6.3 | Offline mode exposes "Copy notes" button | Tasks 7, 8 |
| §6.4 | Annotation JSON shape | Task 6 |
| §10.5 | Offline annotation fallback test | Task 10 step 2 |

**Gaps intentionally deferred:**
- The Designer subagent's instructions for *using* this template (Plan 3).
- The auto-generated `03-prototypes/index.html` landing page that compares alternatives (Plan 3).
- The `proto-maker-server` itself is provided by Plan 1; Task 10 step 3 documents the integration point.
