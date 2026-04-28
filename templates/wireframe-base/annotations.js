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

  async function init(opts) {
    if (activeOverlay) return activeOverlay;
    const screen = (opts && opts.screen) || 'unknown.html';
    const path = (opts && opts.path) || '';
    const mode = await detectMode();
    activeOverlay = { mode, screen, path, notes: [], addNote, exportNotes, copyNotes };
    return activeOverlay;
  }

  global.ProtoMakerAnnotations = { init };
})(typeof window !== 'undefined' ? window : this);
